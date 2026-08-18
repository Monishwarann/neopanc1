import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';

enum ESP32Status { searching, connecting, connected, disconnected }

class ESP32ConnectionService {
  final _statusController = StreamController<ESP32Status>.broadcast();
  Stream<ESP32Status> get statusStream => _statusController.stream;

  final _readingController = StreamController<SensorReading>.broadcast();
  Stream<SensorReading> get readingStream => _readingController.stream;

  ESP32Status _status = ESP32Status.disconnected;
  ESP32Status get status => _status;

  String? _esp32Ip;
  String? get esp32Ip => _esp32Ip;

  String _firmwareVersion = 'v1.0.2 (Stable)';
  String get firmwareVersion => _firmwareVersion;

  int _latency = 0;
  int get latency => _latency;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  SensorReading? _currentReading;
  SensorReading? get currentReading => _currentReading;

  String get connectionQuality {
    if (_status != ESP32Status.connected) return 'Disconnected';
    if (_latency < 30) return 'Excellent';
    if (_latency < 100) return 'Good';
    if (_latency < 250) return 'Fair';
    return 'Weak';
  }

  Timer? _connectTimer;
  bool _isSearching = false;

  void startConnectionLoop(String ssid, String gatewayIp) {
    _statusController.add(_status);
    _connectTimer?.cancel();
    
    // Determine the IP address of the ESP32
    // If connected to ESP32 hotspot, the gateway is usually 192.168.4.1
    if (ssid.toLowerCase().contains('esp32') || ssid.toLowerCase().contains('neopanc') || ssid.toLowerCase().contains('medi_ai') || gatewayIp == '192.168.4.1') {
      _esp32Ip = gatewayIp != 'N/A' && gatewayIp != '--' ? gatewayIp : '192.168.4.1';
    } else {
      // In Station Mode or fallback
      _esp32Ip = 'neopanc.local'; 
    }

    _status = ESP32Status.searching;
    _statusController.add(_status);

    _connectTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isSearching) return;
      _isSearching = true;

      final stopwatch = Stopwatch()..start();
      try {
        final targetUrl = 'http://$_esp32Ip/live';
        final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 1));
        stopwatch.stop();

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _currentReading = SensorReading.fromJson(data);
          _latency = stopwatch.elapsedMilliseconds;
          _lastSync = DateTime.now();
          
          if (_status != ESP32Status.connected) {
            _status = ESP32Status.connected;
            _statusController.add(_status);
          }
          _readingController.add(_currentReading!);
        } else {
          _handleFailure();
        }
      } catch (_) {
        // Fallback check to root or status endpoint
        try {
          final targetUrlFallback = 'http://$_esp32Ip/api/status';
          final response = await http.get(Uri.parse(targetUrlFallback)).timeout(const Duration(seconds: 1));
          stopwatch.stop();
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            // If the status endpoint returns details
            _firmwareVersion = data['firmware'] ?? 'v1.0.2 (Stable)';
            _latency = stopwatch.elapsedMilliseconds;
            _lastSync = DateTime.now();
            if (_status != ESP32Status.connected) {
              _status = ESP32Status.connected;
              _statusController.add(_status);
            }
          } else {
            _handleFailure();
          }
        } catch (_) {
          _handleFailure();
        }
      } finally {
        _isSearching = false;
      }
    });
  }

  void stopConnectionLoop() {
    _connectTimer?.cancel();
    _status = ESP32Status.disconnected;
    _statusController.add(_status);
    _esp32Ip = null;
    _currentReading = null;
  }

  void _handleFailure() {
    if (_status == ESP32Status.connected || _status == ESP32Status.searching) {
      _status = ESP32Status.disconnected;
      _statusController.add(_status);
      _currentReading = null;
    }
  }
}
