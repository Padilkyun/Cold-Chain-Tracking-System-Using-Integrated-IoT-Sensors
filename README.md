# CapsiBox & Tea Cutter Smart System 🌶️🍃

A comprehensive IoT ecosystem designed for smart agriculture, specifically focused on **Smart Chili Storage (CapsiBox)** and **Automated Tea Harvesting (Tea Cutter)**. This project integrates ESP32 hardware, real-time sensor monitoring, and a Flutter mobile application for cross-device control.

## 🌟 Key Features

### 1. CapsiBox (Smart Chili Storage)
*   **Real-time Climate Monitoring:** Tracks Temperature, Humidity, TVOC (Volatile Organic Compounds), and eCO2.
*   **PID Temperature Control:** Uses a Proportional-Integral-Derivative (PID) algorithm to maintain optimal storage temperature via a Peltier cooling system.
*   **Safety Alerts:** Instant mobile notifications when TVOC levels exceed safety thresholds (harmful gases detection).
*   **Historical Data:** Visualizes sensor trends with interactive charts and local SQLite storage for offline data review.

### 2. Tea Harvest (Automated Cutter)
*   **PWM Speed Control:** Precisely adjust the motor speed (0-100%) for tea leaf harvesting.
*   **Live Animation:** Visual blade rotation speed in the app synchronized with the physical motor.
*   **Safety Interlock:** Remote emergency stop and motor status monitoring.

### 3. Mobile Application (Flutter)
*   **Dual-Device Control:** Manage both the storage box and the harvester from a single dashboard.
*   **System Notifications:** Official Android "Heads-up" notifications for critical sensor alerts.
*   **User Profiles:** Personalized profiles with customizable avatars and contact information.
*   **Action Logs:** Detailed history of every command sent to the hardware (audit trail).

## 🛠️ Tech Stack

-   **Mobile:** Flutter (Dart)
-   **Hardware:** ESP32 (Arduino C++)
-   **Local Storage:** SQLite (for sensor history) & SharedPreferences (for user profiles)
-   **Protocols:** 
    -   **ESP-NOW:** For ultra-fast, low-latency communication between sensor node and receiver.
    -   **HTTP REST API:** For mobile-to-hardware communication via ESP32 Access Point.
-   **Sensors:** DHT22 (Temp/Hum), ENS160 (TVOC/eCO2).

## 📐 Architecture

1.  **ESP-Fetch (Sender):** Reads sensors (DHT22, ENS160) and sends data via **ESP-NOW** to the receiver.
2.  **ESP-Receiver (Receiver & Controller):**
    *   Receives ESP-NOW packets.
    *   Runs the **PID Controller** for the Peltier system.
    *   Acts as a **WiFi Access Point** (CapsiBox_AP).
    *   Hosts a **Web Server** to serve data to the Flutter app.
3.  **Flutter App:** Polls the Receiver's API to display data and sends POST requests to control actuators.

## 🚀 Getting Started

### Hardware Setup
1.  Connect DHT22 and ENS160 to the **ESP-Fetch** node.
2.  Connect Peltier (via PWM driver), Fan, and Tea Cutter Motor to the **ESP-Receiver**.
3.  Flash the respective `.cpp` files to the ESP32 boards.
4.  Update the `receiverMAC` in `kodinganfetch.cpp` with your Receiver's MAC address.

### Mobile App Setup
1.  Ensure Flutter is installed.
2.  Run `flutter pub get` to install dependencies.
3.  Connect your phone to the WiFi network: **"CapsiBox_AP"** (Password: `12345678`).
4.  Run `flutter run`.

## 📈 Database Schema (SQLite)
-   `sensor_data`: Stores historical records of Temp, Hum, TVOC, eCO2.
-   `notifications`: Stores a history of received system alerts.
-   `actions`: Tracks user commands (e.g., "Fan turned ON").

---
*Developed for smart agriculture innovation.*
