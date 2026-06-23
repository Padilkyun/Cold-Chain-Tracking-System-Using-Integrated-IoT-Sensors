// =====================================================
// ESP32 RECEIVER + LOCAL WEB SERVER - CAPSI BOX & TEA CUTTER
// =====================================================

#include <esp_now.h>
#include <WiFi.h>
#include <WebServer.h>
#include <PID_v1.h>

// --- WiFi AP Configuration ---
const char* ap_ssid = "CapsiBox_AP";
const char* ap_pass = "12345678";

WebServer server(80);

// --- Actuator Pins ---
const int PELTIER_PWM = 25;
const int KIPAS_PIN   = 18;
const int TEA_CUTTER_PIN = 19; // GPIO Pin for Tea Cutter motor control

// PWM Configuration
const int freq = 20000;
const int res  = 8;
const int TEA_FREQ = 1000; // 1kHz frequency for motor
const int TEA_RES = 8;     // 8-bit resolution

// TVOC Threshold for safety alert
const uint16_t TVOC_THRESHOLD = 1000;

// --- Variables & Controllers ---
double Setpoint  = 19.0;
double InputSuhu = 0.0;
double OutputPWM = 0.0;
double Kp = 50.0, Ki = 1.2, Kd = 10.0;
PID myPID(&InputSuhu, &OutputPWM, &Setpoint, Kp, Ki, Kd, REVERSE);
 
bool modeAuto      = true;
bool manualPeltier = false;
bool manualKipas   = true;

// Tea Cutter states
bool teaCutterActive = false;
int teaCutterSpeed   = 50; // Speed in percentage (0 - 100)

unsigned long lastRecvTime  = 0;
unsigned long lastSerialPrint = 0;
const unsigned long PRINT_INTERVAL = 2000;

typedef struct struct_message {
  float suhu;
  float kelembaban;
  uint16_t tvoc;
  uint16_t eco2;
} struct_message;

struct_message incomingData;
bool dataBaruDiterima = false;

// --- Callback ESP-NOW ---
void onDataRecv(const esp_now_recv_info *info, const uint8_t *incomingDataRaw, int len) {
  Serial.println("\n========================================");
  Serial.println("[ESP-NOW] Data diterima dari ESP1!");
  Serial.printf("  Ukuran data  : %d bytes\n", len);

  memcpy(&incomingData, incomingDataRaw, sizeof(incomingData));
  InputSuhu        = (double)incomingData.suhu;
  lastRecvTime     = millis();
  dataBaruDiterima = true;

  Serial.println("[ESP-NOW] Isi data:");
  Serial.printf("  Suhu         : %.2f C\n", incomingData.suhu);
  Serial.printf("  Kelembaban   : %.2f %%\n", incomingData.kelembaban);
  Serial.printf("  TVOC         : %u ppb\n", incomingData.tvoc);
  Serial.printf("  eCO2         : %u ppm\n", incomingData.eco2);
  Serial.println("========================================");
}

// --- Tea Cutter Motor Update ---
void updateTeaCutter() {
  if (teaCutterActive) {
    // Map 0-100% speed to 0-255 PWM value
    int pwmValue = map(teaCutterSpeed, 0, 100, 0, 255);
    ledcWrite(TEA_CUTTER_PIN, pwmValue);
    Serial.printf("[TEA CUTTER] Aktif. Kecepatan: %d%% (PWM: %d)\n", teaCutterSpeed, pwmValue);
  } else {
    ledcWrite(TEA_CUTTER_PIN, 0);
    Serial.println("[TEA CUTTER] Dinonaktifkan.");
  }
}

// =====================================================
// WEB SERVER HANDLERS (REST API)
// =====================================================

void handleGetData() {
  // Add CORS headers to allow connection from web-based/cross-origin apps if needed
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  bool espNowConnected = (lastRecvTime != 0 && (millis() - lastRecvTime < 6000));

  char json[512];
  snprintf(json, sizeof(json),
    "{\"suhu\":%.2f,\"kelembaban\":%.2f,\"tvoc\":%u,\"eco2\":%u,\"peltier_pwm\":%d,\"mode_auto\":%s,\"manual_peltier\":%s,\"manual_kipas\":%s,\"setpoint\":%.1f,\"tea_cutter_active\":%s,\"tea_cutter_speed\":%d,\"esp_now_connected\":%s}",
    incomingData.suhu,
    incomingData.kelembaban,
    incomingData.tvoc,
    incomingData.eco2,
    (int)OutputPWM,
    modeAuto ? "true" : "false",
    manualPeltier ? "true" : "false",
    manualKipas ? "true" : "false",
    Setpoint,
    teaCutterActive ? "true" : "false",
    teaCutterSpeed,
    espNowConnected ? "true" : "false"
  );
  
  server.send(200, "application/json", json);
}
void handleControl() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  // Handle Mode Auto / Manual
  if (server.hasArg("mode_auto")) {
    int val = server.arg("mode_auto").toInt();
    modeAuto = (val == 1);
    Serial.printf("[API] Mode diubah ke: %s\n", modeAuto ? "AUTO" : "MANUAL");
    
    if (modeAuto) {
      myPID.SetMode(AUTOMATIC);
      digitalWrite(KIPAS_PIN, HIGH);
      manualKipas = true;
    } else {
      myPID.SetMode(MANUAL);
      OutputPWM = 0;
      ledcWrite(PELTIER_PWM, 0);
      manualPeltier = false;
    }
  }
  
  // Handle Manual Peltier PWM
  if (server.hasArg("manual_peltier")) {
    int val = server.arg("manual_peltier").toInt();
    if (!modeAuto) {
      manualPeltier = (val == 1);
      int pwm = manualPeltier ? 200 : 0;
      ledcWrite(PELTIER_PWM, pwm);
      Serial.printf("[API] Peltier manual disetel ke %d\n", pwm);
    }
  }
  
  // Handle Manual Fan Toggle
  if (server.hasArg("manual_kipas")) {
    int val = server.arg("manual_kipas").toInt();
    if (!modeAuto) {
      manualKipas = (val == 1);
      digitalWrite(KIPAS_PIN, manualKipas ? HIGH : LOW);
      Serial.printf("[API] Kipas manual disetel ke %s\n", manualKipas ? "ON" : "OFF");
    }
  }
  
  // Handle Temp Setpoint
  if (server.hasArg("setpoint")) {
    double val = server.arg("setpoint").toDouble();
    Setpoint = val;
    Serial.printf("[API] Setpoint baru: %.1f C\n", Setpoint);
  }
  
  // Handle Tea Cutter state
  if (server.hasArg("tea_cutter_active")) {
    int val = server.arg("tea_cutter_active").toInt();
    teaCutterActive = (val == 1);
    updateTeaCutter();
  }
  
  // Handle Tea Cutter speed
  if (server.hasArg("tea_cutter_speed")) {
    int val = server.arg("tea_cutter_speed").toInt();
    if (val < 0) val = 0;
    if (val > 100) val = 100;
    teaCutterSpeed = val;
    updateTeaCutter();
  }
  
  server.send(200, "application/json", "{\"status\":\"success\"}");
}

// Handle preflight requests for CORS (necessary if accessed from web clients)
void handleOptions() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

// =====================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n========================================");
  Serial.println("  CAPSI BOX & TEA CUTTER - OFFLINE AP");
  Serial.println("========================================");

  // Initialize Actuator Pins
  Serial.println("[SETUP] Inisialisasi pin kipas...");
  pinMode(KIPAS_PIN, OUTPUT);
  digitalWrite(KIPAS_PIN, HIGH);
  
  Serial.println("[SETUP] Inisialisasi pin pemotong teh...");
  pinMode(TEA_CUTTER_PIN, OUTPUT);
  ledcAttach(TEA_CUTTER_PIN, TEA_FREQ, TEA_RES);
  ledcWrite(TEA_CUTTER_PIN, 0); // Off by default

  Serial.println("[SETUP] Inisialisasi PWM Peltier...");
  ledcAttach(PELTIER_PWM, freq, res);
  ledcWrite(PELTIER_PWM, 0);

  Serial.println("[SETUP] Inisialisasi PID...");
  myPID.SetOutputLimits(0, 255);
  myPID.SetMode(AUTOMATIC);
  Serial.printf("[SETUP] PID aktif. Setpoint=%.1f | Kp=%.1f | Ki=%.1f | Kd=%.1f\n",
    Setpoint, Kp, Ki, Kd);

  // Setup WiFi Access Point
  Serial.println("[SETUP] Memulai WiFi SoftAP...");
  WiFi.mode(WIFI_AP);
  // Set AP pada Channel 1 agar sinkron dengan ESP1
  WiFi.softAP(ap_ssid, ap_pass, 1);
  
  IPAddress myIP = WiFi.softAPIP();
  Serial.print("[WIFI] Access Point aktif. SSID: ");
  Serial.println(ap_ssid);
  Serial.print("[WIFI] IP Address ESP32: ");
  Serial.println(myIP);
  Serial.print("[WIFI] MAC Address (SoftAP): ");
  Serial.println(WiFi.softAPmacAddress());
  Serial.println("[WIFI] Berjalan di Channel: 1");

  // Setup Web Server API routing
  server.on("/data", HTTP_GET, handleGetData);
  server.on("/control", HTTP_POST, handleControl);
  server.on("/control", HTTP_OPTIONS, handleOptions);
  server.begin();
  Serial.println("[SETUP] HTTP Web Server berjalan di port 80.");

  // Setup ESP-NOW
  Serial.println("[SETUP] Inisialisasi ESP-NOW...");
  if (esp_now_init() != ESP_OK) {
    Serial.println("[ERROR] Gagal init ESP-NOW! Restart...");
    delay(3000);
    ESP.restart();
  }
  esp_now_register_recv_cb(onDataRecv);
  Serial.println("[SETUP] ESP-NOW siap menerima data dari ESP1.");
  Serial.println("========================================\n");
}

// =====================================================
void loop() {
  // Handle HTTP client request
  server.handleClient();

  // --- PID Compute (Suhu Box) ---
  if (modeAuto) {
    if (myPID.Compute()) {
      // Safety: sensor offline > 5 detik
      if (lastRecvTime != 0 && millis() - lastRecvTime > 5000) {
        Serial.println("\n[SAFETY WARNING] Sensor ESP1 tidak merespons > 5 detik!");
        Serial.println("[SAFETY] Peltier dimatikan demi keamanan.");
        OutputPWM = 0;
      }
      ledcWrite(PELTIER_PWM, (int)OutputPWM);
    }
  }

  // --- Serial Monitoring ---
  if (millis() - lastSerialPrint >= PRINT_INTERVAL) {
    lastSerialPrint = millis();
    
    Serial.println("\n--- STATUS MONITOR ---");
    Serial.printf("Suhu: %.2f C | Kelembaban: %.2f %%\n", incomingData.suhu, incomingData.kelembaban);
    Serial.printf("TVOC: %u ppb | eCO2: %u ppm\n", incomingData.tvoc, incomingData.eco2);
    Serial.printf("Mode: %s | Peltier PWM: %d\n", modeAuto ? "AUTO" : "MANUAL", (int)OutputPWM);
    Serial.printf("Kipas: %s | Pemotong Teh: %s (%d%%)\n", 
      (digitalRead(KIPAS_PIN) == HIGH) ? "ON" : "OFF",
      teaCutterActive ? "AKTIF" : "MATI", teaCutterSpeed);
    
    if (incomingData.tvoc >= TVOC_THRESHOLD) {
      Serial.printf("⚠️ [ALERT] TVOC tinggi (%u ppb >= %u ppb)\n", incomingData.tvoc, TVOC_THRESHOLD);
    }
  }
}