# Patent Application Draft

**TITLE OF THE INVENTION**  
MULTIMODAL SENSOR FUSION AND ENSEMBLE AI DECISION SUPPORT SYSTEM FOR NON-INVASIVE EARLY PANCREATIC CANCER RISK SCREENING

---

## 1. FIELD OF THE INVENTION

The present invention relates generally to biomedical screening systems and Internet-of-Things (IoT) device interfaces. More specifically, the invention relates to a non-invasive screening platform that fuses breath-derived volatile organic compounds (VOCs) and salivary chemical/electrical markers with patient clinical data using an ensemble machine learning pipeline to generate a real-time Pancreatic Cancer Risk Index (PCRI).

---

## 2. BACKGROUND OF THE INVENTION AND PRIOR ART

Pancreatic cancer remains one of the most lethal malignancies, characterized by poor prognosis and high mortality rates, largely due to late-stage diagnosis. Early-stage pancreatic tumors are typically asymptomatic, and current clinical diagnostic methods, such as computed tomography (CT), magnetic resonance imaging (MRI), and endoscopic ultrasound (EUS), are expensive, invasive, and unsuitable for population-wide primary screening.

Volatile Organic Compounds (VOCs) excreted in exhaled breath, such as acetone, ethanol, and various amines, shift in concentration due to altered metabolic states in pancreatic ductal adenocarcinoma (PDAC) patients. Concurrently, salivary markers such as pH and electrical conductivity (EC) experience variations reflecting systemic acid-base and ionic changes related to pancreatic inflammatory status. 

While individual gas sensors and salivary measurements have been studied in isolation, prior art lacks an integrated, low-cost, portable screening architecture capable of:
1. Simultaneously capturing breath VOCs and saliva indicators in a single-session patient screening.
2. Combining these physical sensor feeds with patient clinical risk factors (e.g., late-onset diabetes, smoking history).
3. Utilizing a multi-stage sensor-fusion index calculation combined with machine learning models to output a diagnostic screening classification.

The present invention addresses these limitations by providing a portable IoT device, a Flask REST-driven database engine, and a machine learning pipeline that calculates a continuous 0-100 screening risk metric.

---

## 3. SUMMARY OF THE INVENTION

It is an object of the present invention to provide a non-invasive, low-cost, and portable screening platform that combines:
*   An exhaled breath sensor array channel (comprising MQ135, MQ3, and MQ7 sensors).
*   A salivary biomarker channel (comprising a pH sensor and an electrical conductivity sensor).
*   A digital health questionnaire module capturing patient clinical history and symptomatic factors.
*   An AI prediction engine executing a Random Forest model trained to classify patient risk profiles.
*   A custom Pancreatic Cancer Risk Index (PCRI) algorithm that normalizes and weighs the sensor responses alongside the machine learning confidence level.

---

## 4. DETAILED DESCRIPTION OF THE PREFERRED EMBODIMENT

### 4.1 System Components and Signal Path
Referring to the system layout, a portable device housing an ESP32 microcontroller, an MQ135 sensor, an MQ3 sensor, an MQ7 sensor, a pH probe interface, and an electrical conductivity (EC) sensor is configured. 

The ESP32 is programmed with noise-filtering firmware. To prevent interference with the ESP32’s active WiFi telemetry transceivers, the sensors are wired to ADC1 analog pins. 

```text
               +-------------------------------------------------------+
               |                    ESP32 Firmware                     |
               |                                                       |
 [MQ135] ----->| GPIO 34 (ADC1) ---> Raw Voltages -> PPM Calibration   |
 [MQ3]   ----->| GPIO 35 (ADC1) ---> Moving Average Filters            |
 [MQ7]   ----->| GPIO 32 (ADC1)                                        |
 [pH]    ----->| GPIO 33 (ADC1) ---> Raw Voltages -> pH Conversion     |
 [EC]    ----->| GPIO 39 (ADC1) ---> Voltage -> mS/cm Conductivity     |
               |                                                       |
               |   WiFi Client ---> JSON Formatter ---> HTTP Client     |
               +---------------------------+---------------------------+
                                           |
                                   (Local WiFi/REST)
                                           v
               +-------------------------------------------------------+
               |                  Flask Backend Server                 |
               |                                                       |
               |  Ingests Telemetry  ---> Database Logging (SQLite)    |
               |  Ingests Survey     ---> ML Vector Input              |
               |  Random Forest Model -> Standardized Scaling (Scaler)  |
               |  Calculates PCRI    ---> Generates PDF Report         |
               +-------------------------------------------------------+
```

### 4.2 PCRI Scoring Architecture
The controller calculates the composite risk index according to the equation:
$$PCRI = W_1 \cdot S_{Breath} + W_2 \cdot S_{pH} + W_3 \cdot S_{EC} + W_4 \cdot S_{AI}$$

Where:
*   $W_1, W_2, W_3, W_4$ represent weighting coefficients assigned as $0.30$, $0.20$, $0.20$, and $0.30$ respectively.
*   $S_{Breath}$ is the breath gas index derived from the cumulative sum of calibrated PPM levels from the MQ135, MQ3, and MQ7 sensors:
    $$S_{Breath} = \min\left(100.0, \frac{\text{PPM}_{MQ135} + \text{PPM}_{MQ3} + \text{PPM}_{MQ7}}{350.0} \cdot 100.0\right)$$
*   $S_{pH}$ is the pH deviation index reflecting the absolute deviance from optimal saliva pH of 7.0:
    $$S_{pH} = \min\left(100.0, \frac{|pH - 7.0|}{1.5} \cdot 100.0\right)$$
*   $S_{EC}$ is the salivary electrical conductivity index:
    $$S_{EC} = \max\left(0.0, \min\left(100.0, \frac{\text{EC} - 1.5}{6.0} \cdot 100.0\right)\right)$$
*   $S_{AI}$ is the machine learning probability score derived from the Random Forest model's output distribution:
    $$S_{AI} = (P_{\text{High Risk}} + 0.5 \cdot P_{\text{Moderate Risk}}) \cdot 100.0$$

---

## 5. CLAIMS

### We Claim:

1.  A system for non-invasive early screening of pancreatic cancer risk, comprising:
    *   an exhaled breath analysis channel having a plurality of semiconductor gas sensors for detecting volatile organic compounds (VOCs);
    *   a salivary analysis channel having a pH sensor and an electrical conductivity (EC) sensor;
    *   a data acquisition module comprising a microcontroller configured to read signals from said sensors and transmit telemetry payloads;
    *   a clinical ingestion interface configured to collect patient demographic and symptomatic variables; and
    *   a backend predictive engine configured to process said sensor telemetry and clinical variables using a machine learning model to calculate a composite Pancreatic Cancer Risk Index (PCRI).

2.  The system of claim 1, wherein said plurality of semiconductor gas sensors comprises an MQ135 sensor, an MQ3 sensor, and an MQ7 sensor.

3.  The system of claim 1, wherein said data acquisition module comprises an ESP32 microcontroller, and wherein said analog outputs from said breath analysis channel and salivary analysis channel are mapped to ADC1 channels of said ESP32 microcontroller to prevent collision with active WiFi operations.

4.  The system of claim 1, wherein said backend predictive engine utilizes a Random Forest classifier trained on clinical variables and sensor baseline features to predict risk profiles.

5.  The system of claim 1, wherein said PCRI is calculated as a weighted summation of a normalized breath gas index, a saliva pH deviation index, a salivary electrical conductivity index, and an AI risk probability index:
    $$PCRI = 0.30 \cdot S_{Breath} + 0.20 \cdot S_{pH} + 0.20 \cdot S_{EC} + 0.30 \cdot S_{AI}$$

6.  The system of claim 1, wherein said system outputs a continuous score between 0 and 100, classified into a Low Risk tier (0–40), a Moderate Risk tier (41–70), and a High Risk tier (71–100), accompanied by automated clinical recommendations.
