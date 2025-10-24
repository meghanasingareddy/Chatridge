import 'package:hive/hive.dart';

part 'device.g.dart';

@HiveType(typeId: 1)
class Device extends HiveObject {

  Device({
    required this.name,
    required this.ip,
    required this.lastSeen,
    this.isOnline = true,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'] ?? '',
      ip: json['ip'] ?? '',
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : DateTime.now(),
      isOnline: json['online'] ?? true,
    );
  }
  @HiveField(0)
  String name;

  @HiveField(1)
  String ip;

  @HiveField(2)
  DateTime lastSeen;

  @HiveField(3)
  bool isOnline;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ip': ip,
      'last_seen': lastSeen.toIso8601String(),
      'online': isOnline,
    };
  }

  String get statusText {
    if (isOnline) {
      final now = DateTime.now();
      final diff = now.difference(lastSeen);
      if (diff.inMinutes < 1) {
        return 'Online';
      } else if (diff.inMinutes < 5) {
        return 'Active ${diff.inMinutes}m ago';
      } else {
        return 'Last seen ${diff.inMinutes}m ago';
      }
    }
    return 'Offline';
  }

  bool get isRecentlyActive {
    if (!isOnline) return false;
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    return diff.inMinutes < 5;
  }
}
