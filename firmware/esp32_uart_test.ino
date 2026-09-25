// =====================================================
// ESP32 - UART RECEIVER TEST SKETCH
// Upload to COM7 (ESP32 Dev Module)
// =====================================================

void setup()
{
  Serial.begin(115200);   // Computer USB Monitor (115200 Baud)

  // RX = GPIO 16, TX = GPIO 17 (9600 Baud for Mega Serial1)
  Serial2.begin(9600, SERIAL_8N1, 16, 17);

  delay(1000);

  Serial.println();
  Serial.println("========================");
  Serial.println("ESP32 UART TEST");
  Serial.println("========================");
  Serial.println("Waiting for Mega...");
}

void loop()
{
  if (Serial2.available())
  {
    String data = Serial2.readStringUntil('\n');

    data.trim();

    if (data.length() > 0)
    {
      Serial.print("RECEIVED: ");
      Serial.println(data);
    }
  }

  delay(10);
}
