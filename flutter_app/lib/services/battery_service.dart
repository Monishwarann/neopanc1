import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  Stream<int?>? _batteryStream;

  /// Returns a broadcast stream that emits the current battery percentage.
  /// It polls every 30 seconds and also updates immediately when the charging state changes.
  Stream<int?> get batteryLevelStream {
    if (_batteryStream != null) {
      return _batteryStream!;
    }

    late StreamController<int?> controller;
    Timer? timer;
    StreamSubscription<BatteryState>? stateSub;

    Future<void> emitLevel() async {
      try {
        final level = await _battery.batteryLevel;
        if (!controller.isClosed) {
          controller.add(level);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.add(null);
        }
      }
    }

    controller = StreamController<int?>.broadcast(
      onListen: () {
        // Emit initial value immediately
        emitLevel();

        // Poll every 30 seconds
        timer = Timer.periodic(const Duration(seconds: 30), (_) {
          emitLevel();
        });

        // Listen for state changes (plugged/unplugged) to force an immediate update
        stateSub = _battery.onBatteryStateChanged.listen((_) {
          emitLevel();
        });
      },
      onCancel: () {
        timer?.cancel();
        stateSub?.cancel();
        _batteryStream = null;
      },
    );

    _batteryStream = controller.stream;
    return _batteryStream!;
  }
}
