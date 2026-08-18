# Final Project & Thesis Report

**Project Title:**  
AI-Driven Non-Invasive Multi-Sensor IoT-Based Early Pancreatic Cancer Risk Screening System Using Breath and Saliva Biomarkers

---

## CHAPTER 1: INTRODUCTION

### 1.1 Project Overview
This project presents the design and implementation of a non-invasive risk screening system for early pancreatic cancer indicators. By combining IoT sensor hardware, web servers, and artificial intelligence, the system provides a low-cost, portable alternative to traditional screening models. The platform measures breath volatile organic compounds (VOCs) and salivary biomarkers (pH and electrical conductivity), fusing these metrics with key clinical risk variables to compute a continuous Pancreatic Cancer Risk Index (PCRI).

### 1.2 Problem Statement
Pancreatic ductal adenocarcinoma (PDAC) has one of the lowest survival rates of any oncology classification. Early diagnosis is rare because the pancreas is situated deep in the abdomen, and symptoms do not manifest until metastasis occurs. Existing diagnostic channels rely on high-cost imaging (CT, MRI, EUS) or invasive biopsies. There is an urgent need for an affordable, non-invasive primary screening tool that can identify high-risk individuals in primary care environments, directing them to early oncology evaluations.

---

## CHAPTER 2: LITERATURE REVIEW AND BIOMARKERS

### 2.1 Breath Volatile Organic Compounds (VOCs)
Altered metabolic pathways in cancer cells lead to the excretion of volatile organic compounds through exhaled breath. Studies show that concentrations of ethanol, acetone, acetaldehyde, and various amine derivatives increase significantly in pancreatic cancer cohorts. Sensor models such as the MQ135, MQ3, and MQ7 offer an affordable, responsive array to capture these combined organic compounds in exhaled air.

### 2.2 Salivary Biomarkers
Saliva reflects systemic physiological shifts. Under inflammatory conditions or metabolic dysfunctions relating to pancreatic insufficiency, salivary pH tends to shift toward acidic boundaries. Concurrently, concentrations of inorganic ions and metabolic waste products elevate, driving up salivary electrical conductivity (EC). Monitoring saliva pH and EC provides an accessible, non-invasive secondary channel to capture pancreatic metabolic indicators.

---

## CHAPTER 3: PROPOSED METHODOLOGY

### 3.1 Hardware Block Diagram
The hardware prototype utilizes an ESP32 microcontroller reading inputs from five sensor channels:
*   **MQ135 VOC Sensor** (GPIO 34 - ADC1)
*   **MQ3 Alcohol Sensor** (GPIO 35 - ADC1)
*   **MQ7 CO Sensor** (GPIO 32 - ADC1)
*   **pH Sensor** (GPIO 33 - ADC1)
*   **Electrical Conductivity Sensor** (GPIO 39 - ADC1)

```text
 +--------------+
 | MQ135 Sensor | ----(Analog GPIO 34)----+
 +--------------+                         |
 +--------------+                         |
 |  MQ3 Sensor  | ----(Analog GPIO 35)----+     +-------------------+
 +--------------+                         +---> |       ESP32       | ---> (WiFi / REST JSON)
 +--------------+                         |     |  Microcontroller  |
 |  MQ7 Sensor  | ----(Analog GPIO 32)----+     +-------------------+
 +--------------+                         |
 +--------------+                         |
 |  pH Sensor   | ----(Analog GPIO 33)----+
 +--------------+                         |
 +--------------+                         |
 |  EC Sensor   | ----(Analog GPIO 39)----+
 +--------------+
```

### 3.2 Machine Learning Classifier
The backend executes a Random Forest Classifier trained on a stratified 1,200-sample screening cohort. The training features consist of:
1.  **Clinical survey features:** Age, BMI, Smoking, Alcohol, Diabetes, Family History, Weight Loss, Abdominal Pain, Appetite Changes, Jaundice.
2.  **Physiological sensor inputs:** MQ135, MQ3, MQ7, Saliva pH, Saliva EC.

---

## CHAPTER 4: EXPERIMENTAL RESULTS AND EVALUATION

### 4.1 AI Model Performance
The Random Forest model was evaluated using an 80-20 train-test split:
*   **Model Accuracy:** 84.17%
*   **Precision:** 86% (Low Risk), 50% (Moderate Risk), 90% (High Risk)
*   **Recall:** 99% (Low Risk), 16% (Moderate Risk), 60% (High Risk)

### 4.2 Feature Weight Analysis
The classification tree split importance ranking identifies breath VOCs and saliva conductivity as key screening signals:
1.  **MQ3 PPM (VOC channel):** 17.09%
2.  **MQ135 PPM (VOC channel):** 15.47%
3.  **MQ7 PPM (VOC channel):** 14.94%
4.  **Saliva EC (mS/cm):** 12.72%
5.  **Age:** 11.44%
6.  **Saliva pH:** 8.58%

---

## CHAPTER 5: CONCLUSION & RECOMMENDATIONS

### 5.1 Project Contributions
1.  **Integrated Prototype:** Fuses multiple non-invasive channels (breath and saliva) with clinical histories.
2.  **PCRI Index:** Combines physical sensor variances and ML classifications into a 0-100 metric.
3.  **Preventive Screening:** Offers a low-cost, portable primary tool to detect risk trends early.

### 5.2 Future Research
*   Integration of high-selectivity electrochemical gas sensors.
*   Enlarging clinical cohorts with hospital-supervised trials.
*   Developing low-power Bluetooth Low Energy (BLE) sensor casings.
