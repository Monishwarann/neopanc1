// =====================================================
// ARDUINO MEGA 2560 - UART TEST SKETCH
// Upload to COM8 (Arduino Mega 2560)
// =====================================================

void setup()
{
  Serial.begin(9600);     // USB Debugging (Computer)
  Serial1.begin(9600);    // TX1 = Pin 18

  delay(1000);

  Serial.println("MEGA UART TEST");
}

void loop()
{
  Serial.println("Sending to ESP32...");

  Serial1.println("HELLO_FROM_MEGA");

  delay(1000);
}
