class SensorReading {
  final double mq135Ppm;
  final double mq3Ppm;
  final double mq7Ppm;
  final double salivaPh;
  final double salivaEc;
  final DateTime timestamp;

  SensorReading({
    required this.mq135Ppm,
    required this.mq3Ppm,
    required this.mq7Ppm,
    required this.salivaPh,
    required this.salivaEc,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      final rawTs = json['timestamp'];
      if (rawTs != null && rawTs is String && rawTs != 'LIVE') {
        parsedTime = DateTime.parse(rawTs);
      } else {
        parsedTime = DateTime.now();
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return SensorReading(
      mq135Ppm: (json['mq135_ppm'] as num?)?.toDouble() ?? 0.0,
      mq3Ppm: (json['mq3_ppm'] as num?)?.toDouble() ?? 0.0,
      mq7Ppm: (json['mq7_ppm'] as num?)?.toDouble() ?? 0.0,
      salivaPh: (json['saliva_ph'] as num?)?.toDouble() ?? 7.0,
      salivaEc: (json['saliva_ec'] as num?)?.toDouble() ?? 3.0,
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mq135_ppm': mq135Ppm,
      'mq3_ppm': mq3Ppm,
      'mq7_ppm': mq7Ppm,
      'saliva_ph': salivaPh,
      'saliva_ec': salivaEc,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
