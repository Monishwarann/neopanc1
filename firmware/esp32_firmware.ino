/**
 * AI-Driven Non-Invasive Multi-Sensor Pancreatic Cancer Risk Screening System
 * ESP32 / ESP8266 Firmware (Unified Version with Arduino Mega UART Integration)
 * 
 * Hardware Wiring Connections:
 * Arduino Mega 2560 | ESP32 Pin              | Notes
 * ------------------|------------------------|---------------------------------------
 * TX1 (Pin 18)      | GPIO 16 (RX2)          | Requires 5V to 3.3V Voltage Divider!
 * RX1 (Pin 19)      | GPIO 17 (TX2)          | Optional return channel
 * GND               | GND                    | Shared Ground MANDATORY
 * 
 * Onboard ESP32 ADC Pins (Optional / Local Probes):
 * Sensor            | ESP32 Pin              | Notes
 * ------------------|------------------------|---------------------------------------
 * Saliva pH         | GPIO 33                | Buffer calibration 4.01 & 7.00
 * Saliva EC         | GPIO 39                | Ionic conductance in mS/cm
 */

#ifdef ESP8266
  #include <ESP8266WiFi.h>
  #include <ESP8266HTTPClient.h>
  #include <ESP8266WebServer.h>
  #include <WiFiClient.h>
  ESP8266WebServer server(80);
#else
  #include <WiFi.h>
  #include <HTTPClient.h>
  #include <WebServer.h>
  WebServer server(80);
#endif

#include <ArduinoJson.h>

// WiFi Credentials
const char* ssid = "Jeeva";
const char* password = "jeeva2006";

// Server API Endpoint
const char* serverEndpoint = "http://10.209.123.189:5000/api/telemetry";

// Simulation Toggle
#ifdef ESP8266
  #define SIMULATE_SENSORS 1
#else
  #define SIMULATE_SENSORS 0
#endif

// Core Configurations
const int USER_ID = 1;
const int SAMPLING_INTERVAL_MS = 5000;
const int ADC_RESOLUTION = 4095;
const float ESP32_VCC = 3.3;

#ifndef ESP8266
// HardwareSerial 2 Pins for Arduino Mega Communication
#define RX2_PIN 16
#define TX2_PIN 17

// Onboard Sensor Pins (ESP32 ADC1)
const int PIN_MQ135 = 34;
const int PIN_MQ3   = 35;
const int PIN_MQ7   = 32;
const int PIN_PH    = 33;
const int PIN_EC    = 39;
#endif

// Live Telemetry Data Received from Arduino Mega / Sensors
int   mega_tds_raw = 0;
int   mega_mq_raw  = 0;
float mq135_ppm    = 0.0;
float mq3_ppm      = 0.0;
float mq7_ppm      = 0.0;
float saliva_ph    = 7.0;
float saliva_ec    = 3.0;

// Helper: Convert Mega TDS raw reading (5V, 10-bit) to PPM
float calculateTDS_PPM(int rawAdc) {
  float voltage = rawAdc * (5.0 / 1023.0);
  float ppm = (133.42 * pow(voltage, 3) - 255.86 * pow(voltage, 2) + 857.39 * voltage) * 0.5;
  return max(0.0f, ppm);
}

// Helper: Convert Mega MQ raw reading to PPM
float calculateMQ_PPM(int rawAdc) {
  float voltage = rawAdc * (5.0 / 1023.0);
  float ppm = voltage * 80.0; // Scaled PPM approximation
  return max(0.0f, ppm);
}

void handleLiveEndpoint() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  StaticJsonDocument<256> doc;
  doc["mq135_ppm"] = mq135_ppm;
  doc["mq3_ppm"]   = mq3_ppm;
  doc["mq7_ppm"]   = mq7_ppm;
  doc["saliva_ph"] = saliva_ph;
  doc["saliva_ec"] = saliva_ec;
  doc["timestamp"] = "LIVE";

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleStatusEndpoint() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  StaticJsonDocument<128> doc;
  doc["status"]   = "connected";
  doc["firmware"] = "v1.0.2 (Mega-UART)";
  doc["ip"]       = WiFi.localIP().toString();

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void connectToWiFi() {
  Serial.print("Connecting to WiFi network: ");
  Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected successfully!");
    Serial.print("ESP32 IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi connection failed! Offline mode active.");
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  #ifndef ESP8266
    // Initialize HardwareSerial 2 to receive data from Arduino Mega 2560 (Serial1)
    Serial2.begin(9600, SERIAL_8N1, RX2_PIN, TX2_PIN);
    Serial.println("Serial2 initialized (RX2=GPIO16, TX2=GPIO17) at 9600 baud.");

    analogReadResolution(12);
    pinMode(PIN_PH, INPUT);
    pinMode(PIN_EC, INPUT);
  #endif
  
  connectToWiFi();

  // Register WebServer Endpoints for Flutter App Direct Polling
  server.on("/live", handleLiveEndpoint);
  server.on("/api/status", handleStatusEndpoint);
  server.begin();
  Serial.println("ESP32 Local HTTP WebServer started on port 80.");
}

unsigned long lastPostTime = 0;

void loop() {
  // Handle incoming HTTP requests from Flutter App
  server.handleClient();

  #ifndef ESP8266
  // 1. Check for incoming Serial data from Arduino Mega 2560
  if (Serial2.available() > 0) {
    String payload = Serial2.readStringUntil('\n');
    payload.trim();

    // Parse packet formatted as: "TDS=xxx,MQ=yyy"
    int tdsIdx = payload.indexOf("TDS=");
    int mqIdx  = payload.indexOf(",MQ=");

    if (tdsIdx != -1 && mqIdx != -1) {
      mega_tds_raw = payload.substring(tdsIdx + 4, mqIdx).toInt();
      mega_mq_raw  = payload.substring(mqIdx + 4).toInt();

      // Convert Mega raw readings
      mq135_ppm = calculateMQ_PPM(mega_mq_raw);
      float tdsPpm = calculateTDS_PPM(mega_tds_raw);
      saliva_ec = tdsPpm / 500.0; // Standard conversion EC (mS/cm) from TDS (PPM)

      Serial.printf("[Mega UART] TDS Raw: %d (EC: %.2f mS/cm) | MQ Raw: %d (VOC: %.2f PPM)\n",
                    mega_tds_raw, saliva_ec, mega_mq_raw, mq135_ppm);
    }
  }
  #endif

  #if SIMULATE_SENSORS
    mq135_ppm = random(200, 400) / 10.0;
    mq3_ppm   = random(80, 150) / 10.0;
    mq7_ppm   = random(20, 80) / 10.0;
    saliva_ph = 6.5 + (random(0, 50) / 100.0);
    saliva_ec = 1.5 + (random(0, 100) / 100.0);
  #endif

  // 2. Periodically transmit telemetry payload to Flask Backend
  unsigned long currentMillis = millis();
  if (currentMillis - lastPostTime >= SAMPLING_INTERVAL_MS) {
    lastPostTime = currentMillis;

    Serial.println("\n--- Current Sensor Metrics ---");
    Serial.printf("MQ135 (VOC): %.2f PPM\n", mq135_ppm);
    Serial.printf("Saliva pH: %.2f pH\n", saliva_ph);
    Serial.printf("Saliva EC: %.2f mS/cm (From Mega TDS Raw %d)\n", saliva_ec, mega_tds_raw);

    if (WiFi.status() == WL_CONNECTED) {
      #ifdef ESP8266
        WiFiClient client;
        HTTPClient http;
        http.setTimeout(5000);
        bool beginSuccess = http.begin(client, serverEndpoint);
      #else
        HTTPClient http;
        http.setTimeout(5000);
        bool beginSuccess = http.begin(serverEndpoint);
      #endif

      if (beginSuccess) {
        http.addHeader("Content-Type", "application/json");

        String payload = "{";
        payload += "\"user_id\":\"" + String(USER_ID) + "\",";
        payload += "\"mq135_ppm\":" + String(mq135_ppm, 2) + ",";
        payload += "\"mq3_ppm\":" + String(mq3_ppm, 2) + ",";
        payload += "\"mq7_ppm\":" + String(mq7_ppm, 2) + ",";
        payload += "\"saliva_ph\":" + String(saliva_ph, 2) + ",";
        payload += "\"saliva_ec\":" + String(saliva_ec, 2);
        payload += "}";

        Serial.println("Transmitting telemetry to Flask API backend...");
        int httpResponseCode = http.POST(payload);
        Serial.printf("Server HTTP Response Code: %d\n", httpResponseCode);
        http.end();
      }
    } else {
      Serial.println("Offline: WiFi connection unavailable. Retrying...");
      connectToWiFi();
    }
  }
}

