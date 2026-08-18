/**
 * AI-Driven Non-Invasive Multi-Sensor Pancreatic Cancer Risk Screening System
 * ESP32 / ESP8266 Firmware (Unified Version)
 * 
 * Hardware Wiring Connections (ESP32 ADC1 Only!):
 * Sensor       | ESP32 Pin              | Notes
 * -------------|------------------------|---------------------------------------
 * MQ135 VOC    | GPIO 34                | Requires external 5V VCC, share GND
 * MQ3 Alcohol  | GPIO 35                | Requires external 5V VCC, share GND
 * MQ7 CO       | GPIO 32                | Requires external 5V VCC, share GND
 * Saliva pH    | GPIO 33                | Calibration via 4.01 and 7.00 buffers
 * Saliva EC    | GPIO 39                | Measures ionic conductance in mS/cm
 * 
 * CRITICAL DESIGN NOTE:
 * ESP32 ADC2 pins are disabled when WiFi is enabled. 
 * Therefore, we MUST use ADC1 pins: GPIO 32, 33, 34, 35, 36, 39.
 * 
 * ESP8266 NOTE:
 * Automatically uses simulated sensor values since the ESP8266 has only one ADC pin (A0).
 */

#ifdef ESP8266
  #include <ESP8266WiFi.h>
  #include <ESP8266HTTPClient.h>
  #include <WiFiClient.h>
#else
  #include <WiFi.h>
  #include <HTTPClient.h>
#endif

// WiFi Credentials (Merged from User Request)
const char* ssid = "Jeeva";
const char* password = "jeeva2006";

// Server API Endpoint (Merged from User Request)
const char* serverEndpoint = "http://10.209.123.189:5000/api/telemetry";

// Simulation Toggle
// Set to 1 to simulate sensor readings (useful for testing without physical sensors)
// Automatically enabled on ESP8266
#ifdef ESP8266
  #define SIMULATE_SENSORS 1
#else
  #define SIMULATE_SENSORS 0
#endif

// Core Configurations
const int USER_ID = 1;                 // Map to target patient profile
const int SAMPLING_INTERVAL_MS = 5000;   // Ingestion rate (5 seconds)
const int ADC_RESOLUTION = 4095;       // 12-bit ADC on ESP32
const float ESP32_VCC = 3.3;           // Operating reference voltage

#ifndef ESP8266
// Sensor Pin Declarations (ADC1 Channels for ESP32)
const int PIN_MQ135 = 34;
const int PIN_MQ3 = 35;
const int PIN_MQ7 = 32;
const int PIN_PH = 33;
const int PIN_EC = 39;

// MQ Sensors Calibration Parameters
// In a production build, these are calculated by running calibration in clean air.
float mq135_R0 = 10.0; // Calibration factor for MQ135 (Kohms)
float mq3_R0 = 10.0;   // Calibration factor for MQ3 (Kohms)
float mq7_R0 = 10.0;   // Calibration factor for MQ7 (Kohms)

// pH Sensor Parameters
float ph_calibration_offset = 0.00; // Calculated during buffer calibration

// Read Analog average helper (reduces high frequency ADC noise)
float readAnalogAverage(int pin, int samples = 20) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delay(5);
  }
  return (float)sum / samples;
}

// Convert MQ Sensor Analog reading to PPM estimate
float calculateMQ_PPM(float raw_adc, float R0, float rl_val = 1.0, float clean_air_ratio = 3.6) {
  float voltage = (raw_adc / ADC_RESOLUTION) * ESP32_VCC;
  if (voltage >= ESP32_VCC) voltage = ESP32_VCC - 0.01; // Avoid division by zero
  
  // Calculate sensor resistance RS
  float rs_gas = ((ESP32_VCC - voltage) * rl_val) / voltage;
  
  // Basic PPM approximation mapping: PPM = a * (RS/R0)^b
  // Values approximated from typical MQ datasheets
  float ratio = rs_gas / R0;
  float ppm = 116.6 * pow(ratio, -2.76); // General VOC curve base
  return max(0.0f, ppm);
}

// Convert pH sensor reading to pH units
float calculateSalivaPH(float raw_adc) {
  float voltage = (raw_adc / ADC_RESOLUTION) * ESP32_VCC;
  // Linear scale mapping for typical 0-3V pH probes
  // Midpoint (7.0 pH) typically reads ~1.5V on calibrated modules
  float pH = 7.0 + ((1.65 - voltage) / 0.18) + ph_calibration_offset;
  return max(0.0f, min(14.0f, pH));
}

// Convert EC sensor reading to mS/cm units
float calculateSalivaEC(float raw_adc) {
  float voltage = (raw_adc / ADC_RESOLUTION) * ESP32_VCC;
  // Conductivity mapping based on typical probe characteristics
  // Conductivity EC (mS/cm) = standard voltage coefficient
  float ec = (voltage * 2.5); // Example calibration scaling
  return max(0.0f, ec);
}
#endif

void connectToWiFi() {
  Serial.print("Connecting to WiFi network: ");
  Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(1000);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected successfully!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi connection failed! Continuing offline mode...");
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  #ifndef ESP8266
    // Configure input resolution (ESP32 specific)
    analogReadResolution(12); // 0 to 4095 range
    
    // Initialize Pins
    pinMode(PIN_MQ135, INPUT);
    pinMode(PIN_MQ3, INPUT);
    pinMode(PIN_MQ7, INPUT);
    pinMode(PIN_PH, INPUT);
    pinMode(PIN_EC, INPUT);
    
    randomSeed(analogRead(34)); // Seed using one of the ADC1 pins
  #else
    randomSeed(analogRead(A0));
  #endif
  
  connectToWiFi();
  Serial.println("System Initialized. Starting sensor telemetry loop...");
}

void loop() {
  float mq135_ppm = 0.0;
  float mq3_ppm = 0.0;
  float mq7_ppm = 0.0;
  float saliva_ph = 7.0;
  float saliva_ec = 3.0;

  #if SIMULATE_SENSORS
    // Sample/Mock Sensor Values (Merged from user ranges)
    mq135_ppm = random(200, 400) / 10.0;       // Equivalent to random(20, 40)
    mq3_ppm = random(80, 150) / 10.0;          // Equivalent to random(8, 15)
    mq7_ppm = random(20, 80) / 10.0;           // Equivalent to random(2, 8)
    saliva_ph = 6.5 + (random(0, 50) / 100.0);  // Equivalent to 6.5 + random(0, 50) / 100.0
    saliva_ec = 1.5 + (random(0, 100) / 100.0); // Equivalent to 1.5 + random(0, 100) / 100.0
  #else
    // 1. Gather filtered readings from physical ESP32 hardware
    float raw_mq135 = readAnalogAverage(PIN_MQ135);
    float raw_mq3   = readAnalogAverage(PIN_MQ3);
    float raw_mq7   = readAnalogAverage(PIN_MQ7);
    float raw_ph    = readAnalogAverage(PIN_PH);
    float raw_ec    = readAnalogAverage(PIN_EC);
    
    // 2. Perform sensor calibrations and conversions
    mq135_ppm = calculateMQ_PPM(raw_mq135, mq135_R0);
    mq3_ppm   = calculateMQ_PPM(raw_mq3, mq3_R0);
    mq7_ppm   = calculateMQ_PPM(raw_mq7, mq7_R0);
    saliva_ph = calculateSalivaPH(raw_ph);
    saliva_ec = calculateSalivaEC(raw_ec);
  #endif
  
  // Print values locally to serial console
  Serial.println("\n--- Telemetry Metrics ---");
  Serial.printf("MQ135 (VOC): %.2f PPM\n", mq135_ppm);
  Serial.printf("MQ3 (Alcohol): %.2f PPM\n", mq3_ppm);
  Serial.printf("MQ7 (CO): %.2f PPM\n", mq7_ppm);
  Serial.printf("Saliva pH: %.2f pH\n", saliva_ph);
  Serial.printf("Saliva EC: %.2f mS/cm\n", saliva_ec);
  
  // 3. Send data to Flask API if WiFi is active
  if (WiFi.status() == WL_CONNECTED) {
    #ifdef ESP8266
      WiFiClient client;
      HTTPClient http;
      http.setTimeout(10000);
      bool beginSuccess = http.begin(client, serverEndpoint);
    #else
      HTTPClient http;
      http.setTimeout(10000);
      bool beginSuccess = http.begin(serverEndpoint);
    #endif

    if (beginSuccess) {
      http.addHeader("Content-Type", "application/json");
      
      // Construct JSON payload matching the Flask API schema
      String payload = "{";
      payload += "\"user_id\":\"" + String(USER_ID) + "\","; // Send user_id as required by the backend
      payload += "\"mq135_ppm\":" + String(mq135_ppm, 2) + ",";
      payload += "\"mq3_ppm\":" + String(mq3_ppm, 2) + ",";
      payload += "\"mq7_ppm\":" + String(mq7_ppm, 2) + ",";
      payload += "\"saliva_ph\":" + String(saliva_ph, 2) + ",";
      payload += "\"saliva_ec\":" + String(saliva_ec, 2);
      payload += "}";
      
      Serial.println("Transmitting payload to API endpoint...");
      Serial.println(payload);
      
      int httpResponseCode = http.POST(payload);
      
      Serial.print("Server HTTP Code: ");
      Serial.println(httpResponseCode);
      
      if (httpResponseCode > 0) {
        String response = http.getString();
        Serial.print("Response: ");
        Serial.println(response);
      } else {
        Serial.print("HTTP Error: ");
        Serial.println(http.errorToString(httpResponseCode));
      }
      http.end();
    } else {
      Serial.println("Unable to connect to server endpoint");
    }
  } else {
    Serial.println("System offline: WiFi connection unavailable. Telemetry outputted to Serial only.");
    // Reconnect check
    connectToWiFi();
  }
  
  delay(SAMPLING_INTERVAL_MS);
}
