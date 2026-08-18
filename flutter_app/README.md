# NeoPanc - AI-Powered Pancreatic Cancer Risk Screening

## Overview
NeoPanc is an AI‑driven, non‑invasive pancreatic cancer screening system that leverages IoT sensors, a Flutter front‑end, and machine‑learning models running in the backend. The app collects physiological data via ESP32 devices, sends it to a Python‑based inference service, and presents risk predictions to the user in real time.

## Features
- Real‑time sensor data acquisition from ESP32 devices
- Secure authentication with Firebase
- Cloud‑hosted machine‑learning inference for cancer risk scoring
- Interactive UI with animated glass‑morphism components
- Offline support and local caching of results
- Cross‑platform deployment (Android, iOS, Web)

## Architecture Diagram
```mermaid
graph TD;
    UI[Flutter UI] -->|Events| State[State Management (Provider/BLoC)];
    State -->|Calls| Services[Service Layer];
    Services -->|REST| Backend[Python ML Backend];
    Services -->|Firebase| Auth[Firebase Auth];
    Services -->|Firebase| DB[Firebase Firestore];
    Services -->|BLE| Sensors[ESP32 Sensors];
    Backend -->|Model| ML[ML Model (PyTorch/TensorFlow)];
    Sensors -->|Data| UI;
```

## Project Structure
```text
flutter_app/
├─ lib/
│  ├─ models/                # Data models (Patient, SensorReading)
│  │   ├─ patient.dart
│  │   └─ sensor_reading.dart
│  ├─ screens/                # UI screens (splash, onboarding, sensor, prediction, etc.)
│  │   ├─ splash_screen.dart
│  │   ├─ sensor_screen.dart
│  │   ├─ prediction_screen.dart
│  │   └─ ...
│  ├─ services/               # Business logic & external integrations
│  │   ├─ api_service.dart
│  │   ├─ authentication_service.dart
│  │   ├─ battery_service.dart
│  │   └─ ...
│  ├─ theme/                  # App theming (dark mode, colors, fonts)
│  │   └─ app_theme.dart
│  ├─ widgets/                # Re‑usable UI components (glass cards, dialogs, etc.)
│  │   ├─ glass_card.dart
│  │   └─ ...
│  └─ main.dart               # Application entry point
├─ assets/                    # Images, fonts, and other assets
│   └─ images/
├─ android/                   # Android native project
├─ ios/                       # iOS native project
├─ test/                      # Widget and unit tests
├─ pubspec.yaml               # Flutter dependencies and assets
└─ README.md                  # This documentation file
```

## Technology Stack
- **Flutter & Dart** – Cross‑platform UI framework
- **Firebase** – Authentication, Firestore, Cloud Messaging
- **Python** – Backend API & ML inference service
- **ESP32** – BLE sensor hardware
- **Git & GitHub** – Version control and CI/CD pipelines

## Setup & Development
```bash
# Clone the repository (already done)
# Navigate to the Flutter app directory
cd flutter_app

# Install Flutter dependencies
flutter pub get

# Run the app on a connected device or emulator
flutter run
```
For additional platform‑specific instructions, refer to the Flutter documentation.

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes and ensure they pass `flutter test`
4. Submit a pull request with a clear description of your changes

## License
This project is licensed under the MIT License – see the `LICENSE` file for details.
