# System Architecture and Data Flows

This document visualizes the software subsystems, execution sequences, and data flows of the NeoPanc system.

## Subsystem Architecture Block Diagram

```mermaid
graph TB
    subgraph Hardware Layer (IoT Device)
        Sensors[MQ135, MQ3, MQ7, pH, EC] -->|Analog Voltage| ADC[ESP32 ADC1 Multiplexer]
        ADC -->|12-bit Quantized Value| Calibration[Firmware Calibration Equations]
        Calibration -->|PPM, pH, mS/cm Values| ESP32Core[ESP32 Core Microcontroller]
        ESP32Core -->|WiFi client| HTTPClient[HTTP client / JSON Serializer]
    end

    subgraph Communication Channel
        HTTPClient -->|HTTP POST Request| WiFi[WiFi / Local Access Point]
        WiFi -->|JSON Payload over REST API| FlaskREST[Flask REST Ingestion Endpoint]
    end

    subgraph Backend Intelligence Layer (Flask App)
        FlaskREST -->|Write Raw Telemetry| DB[(SQLite Database)]
        DB -->|Query Historical Context| HistoryQuery[History Logger]
        
        FlaskREST -->|Forward Telemetry Data| PredictionEngine[Risk Ingestion Engine]
        Questionnaire[Digital Questionnaire Input] -->|POST Form Data| PredictionEngine
        
        PredictionEngine -->|Scaled Clinical + Sensor Arrays| Scaler[StandardScaler pkl]
        Scaler -->|Normalized Vectors| RFClassifier[Random Forest Classifier pkl]
        
        RFClassifier -->|Risk Levels & Confidence Scores| PCRIEngine[PCRI Fusion Score Engine]
        PCRIEngine -->|Combined Index Calculation| LogReport[Database Screening Logs]
        
        LogReport -->|HTML REST Serializer| ResponseJSON[Response JSON Object]
        LogReport -->|ReportLab Document Generator| PDFGenerator[PDF Report Compiler]
    end

    subgraph Client Application Layer
        ResponseJSON -->|API Ingestion| FlutterApp[Flutter Mobile Application]
        ResponseJSON -->|Fetch / AJAX | WebDashboard[Web Screening Dashboard]
        PDFGenerator -->|PDF Attachment download| ClientBrowser[Web / App PDF Download]
    end
```

---

## Detailed Evaluation Processing Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Patient as Patient (App/Dashboard)
    participant Client as Client Application Interface
    participant ESP32 as ESP32 Hardware Device
    participant API as Flask Server REST API
    participant Model as AI Model Classifier (Random Forest)
    participant DB as SQLite Database
    
    Note over ESP32: Sensor Ingestion Loop (5s Interval)
    ESP32->>ESP32: Collect Analog Voltages
    ESP32->>ESP32: Apply Moving Average Filters
    ESP32->>ESP32: Convert to Units (PPM, pH, mS/cm)
    ESP32->>API: HTTP POST /api/telemetry (JSON Data)
    API->>DB: INSERT INTO sensor_readings
    
    Note over Patient, Client: Risk Evaluation Sequence
    Patient->>Client: Fills clinical questionnaire
    Patient->>Client: Clicks "Evaluate Pancreatic Risk"
    Client->>API: HTTP POST /api/predict (Form Data + Sensor parameters)
    API->>DB: INSERT INTO questionnaires
    API->>API: Query latest sensor readings from DB (if not posted)
    API->>Model: Execute StandardScaler on consolidated data
    API->>Model: Run Random Forest Classifier (predict & predict_proba)
    Model-->>API: Returns Class (0/1/2) + Probability Distribution
    API->>API: Calculate custom PCRI index using sensor & AI weights
    API->>API: Formulate clinical recommendation notes
    API->>DB: INSERT INTO screening_logs (PCRI, Class, Advice)
    API-->>Client: Returns 200 OK (JSON Risk breakdown)
    Client->>Patient: Renders Gauge needle, risk status, and component scores
    
    Note over Patient, Client: PDF Export Request
    Patient->>Client: Clicks "Download PDF Report"
    Client->>API: HTTP GET /api/generate-pdf/<log_id>
    API->>DB: Query User, Sensor, Questionnaire & Log records
    API->>API: Generate PDF canvas (ReportLab)
    API-->>Client: Stream PDF document attachment
    Client->>Patient: Displays PDF Viewer / Download prompt
```
