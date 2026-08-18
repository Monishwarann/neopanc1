# User Manual & Operating Guide

Welcome to the **Neo-Panc Pancreatic Cancer Risk Screening System**. This manual guides you through hardware calibration, server setup, and software operations.

---

## 1. Hardware Assembly and Setup

### 1.1 Sensor Burn-In Protocol
Metal-oxide semiconductor (MOS) sensors (MQ135, MQ3, MQ7) contain an internal heating element that must be "seasoned" to burn off chemical residues from manufacturing.
*   **Initial Burn-In:** Plug the MQ sensors into a 5V power supply and let them run continuously for **24 to 48 hours** before taking measurements.
*   **Pre-test Warm-up:** Before conducting any screening session, power on the device and wait **3 to 5 minutes** for the sensors to reach thermal stabilization.

### 1.2 MQ Gas Sensor R0 Calibration
To calibrate the gas baseline ($R_0$) in clean ambient air:
1.  Verify the sensor is in a well-ventilated room with clean air.
2.  Power on the device and measure the analog voltage output ($V_{out}$).
3.  Calculate sensor resistance in air ($R_s$):
    $$R_s = \frac{V_{cc} - V_{out}}{V_{out}} \cdot R_L$$ (where $R_L = 1.0\text{ k}\Omega$ on typical breakout boards).
4.  Divide $R_s$ by the clean air ratio specified in the datasheet (typically $3.6$ for MQ135) to find $R_0$:
    $$R_0 = \frac{R_s}{\text{Ratio}_{\text{Clean Air}}}$$
5.  Input this $R_0$ value into your `esp32_firmware.ino` variables.

### 1.3 Saliva pH Probe 2-Point Calibration
1.  Pour standard pH buffer solutions (pH 7.00 and pH 4.01) into clean cups.
2.  Rinse the pH electrode in distilled water and submerge it in the pH 7.00 buffer. Adjust the calibration dial on the driver module until the serial log reads exactly `7.00`.
3.  Rinse the electrode and submerge it in the pH 4.01 buffer. Note any deviance in the serial output and input it as `ph_calibration_offset` in the firmware.

---

## 2. Running the Flask Backend and Web Dashboard

### 2.1 Dependencies Installation
Ensure Python 3.10+ is installed on your computer. Install requirements using command-line:
```bash
pip install -r backend/requirements.txt
```

### 2.2 Running the Application
1.  Navigate to the `backend/` directory:
    ```bash
    python app.py
    ```
2.  Open your web browser and go to `http://localhost:5000`.
3.  The dashboard will load in Demo Mode automatically. To create a personal profile, click **Login** -> **Register Account**.

---

## 3. Running the Web Simulator
If you do not have physical ESP32 hardware, use the **Virtual ESP32 Simulator** on the left panel of the web dashboard:
1.  Adjust the sliders to set simulated MQ PPM, pH, and electrical conductivity.
2.  Enable **Continuous Feed** to push telemetry to the server every 5 seconds.
3.  Fill out the **Clinical Risk Questionnaire** on the main dashboard and click **Evaluate**.
4.  View your PCRI risk dial and click **Download PDF Report** to export the printable document.

---

## 4. Troubleshooting

*   **ESP32 Serial Log reads "HTTP Error code: -1":** The ESP32 is unable to reach the Flask server. Ensure your computer and ESP32 are connected to the exact same WiFi network. Check the `serverEndpoint` string in `esp32_firmware.ino` and make sure it matches your computer's local IP address (e.g., `http://192.168.1.50:5000/api/telemetry`).
*   **Sensor values read flat 0 or 4095:** Ensure your sensor is connected to ADC1 pins (GPIO 32, 33, 34, 35, 39). Check that the sensor's ground is connected to the ESP32 ground.
*   **Flask throws "Address already in use":** Another process is using port 5000. Stop other Python servers, or edit the `app.run` command in `app.py` to run on a different port (e.g., `port=8080`).
