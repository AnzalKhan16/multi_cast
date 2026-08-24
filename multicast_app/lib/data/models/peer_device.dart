import '../../core/enums/device_type.dart';

class PeerDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final DeviceType deviceType;
  final double signalStrength;

  PeerDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.deviceType = DeviceType.unknown,
    this.signalStrength = 0.0,
  });

  PeerDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceType? deviceType,
    double? signalStrength,
  }) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      deviceType: deviceType ?? this.deviceType,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }
}
