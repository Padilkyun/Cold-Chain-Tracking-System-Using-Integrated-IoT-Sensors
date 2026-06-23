#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <Wire.h>
#include "DHT.h"
#include "DFRobot_ENS160.h"

// --- Konfigurasi Pin & Sensor ---
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Alamat I2C ENS160 biasanya 0x53
DFRobot_ENS160_I2C ENS160(&Wire, 0x53); 

// --- Struktur Data untuk ESP-NOW (Harus sama dengan Receiver) ---
typedef struct struct_message {
  float suhu;
  float kelembaban;
  uint16_t tvoc;
  uint16_t eco2;
} struct_message;

struct_message sensorData;

// Ganti dengan MAC Address ESP32 Receiver Anda
uint8_t receiverMAC[] = {0x48, 0xE7, 0x29, 0xB6, 0x78, 0x9D}; //48:E7:29:B6:78:9D
esp_now_peer_info_t peerInfo;

// --- FUNGSI CALLBACK (Untuk Core 3.x) ---
void onDataSent(const wifi_tx_info_t *tx_info, esp_now_send_status_t status) {
  Serial.print("\r\nStatus Pengiriman Terakhir: ");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "SUKSES" : "GAGAL (Receiver tidak merespons)");
}

void setup() {
  Serial.begin(115200);
  
  // Inisialisasi I2C & DHT
  Wire.begin(21, 22);
  dht.begin();

  // Inisialisasi ENS160
  while(ENS160.begin() != 0){
    Serial.println("Gagal mendeteksi ENS160! Cek kabel SDA/SCL");
    delay(1000);
  }
  
  // Set mode operasi standar
  ENS160.setPWRMode(ENS160_STANDARD_MODE);

  // Inisialisasi WiFi & ESP-NOW
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(); // Pastikan tidak mencoba konek ke router lain

  // SINKRONISASI CHANNEL: Harus sama dengan channel AP receiver
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(1, WIFI_SECOND_CHAN_NONE);
  esp_wifi_set_promiscuous(false);

  if (esp_now_init() != ESP_OK) {
    Serial.println("Gagal inisialisasi ESP-NOW");
    return;
  }

  // Daftarkan Callback
  esp_now_register_send_cb((esp_now_send_cb_t)onDataSent);
  
  // Daftarkan Peer (Receiver)
  memcpy(peerInfo.peer_addr, receiverMAC, 6);
  peerInfo.channel = 1; // Samakan dengan channel AP (1)
  peerInfo.encrypt = false;
  
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Gagal menambahkan peer");
    return;
  }
}

void loop() {
  // 1. Baca Data DHT22 untuk kompensasi
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println("Gagal membaca DHT22! Menggunakan nilai default...");
    // Nilai fallback jika DHT mati
    sensorData.suhu = 25.0; 
    sensorData.kelembaban = 50.0;
  } else {
    sensorData.suhu = t - 0.1; 
    sensorData.kelembaban = h - 4.5;
    
    if (sensorData.kelembaban < 0) sensorData.kelembaban = 0;
    if (sensorData.kelembaban > 100) sensorData.kelembaban = 100;
  }
  
  // Kirim kompensasi lingkungan ke ENS160
  ENS160.setTempAndHum(sensorData.suhu, sensorData.kelembaban);

  // 2. Baca Data ENS160
  uint8_t statusENS = ENS160.getENS160Status();
  
  // MODIFIKASI: Kita tetap baca data meskipun status masih 1 atau 2 
  // agar Serial Monitor tidak tampil 0 terus.
  sensorData.tvoc = ENS160.getTVOC();
  sensorData.eco2 = ENS160.getECO2();

  // 3. Monitoring Serial
  Serial.println("\n--- MONITORING SENSOR ---");
  Serial.print("Status ENS160: "); 
  Serial.println(statusENS); // 0: OK, 1: Warming up, 2: Initializing
  
  Serial.printf("Suhu: %.2f C | Hum: %.2f %%\n", sensorData.suhu, sensorData.kelembaban);
  Serial.printf("TVOC: %d ppb | eCO2: %d ppm\n", sensorData.tvoc, sensorData.eco2);

  // 4. Kirim data via ESP-NOW
  esp_err_t result = esp_now_send(receiverMAC, (uint8_t *)&sensorData, sizeof(sensorData));
  
  // Delay 2 detik
  delay(2000);
}