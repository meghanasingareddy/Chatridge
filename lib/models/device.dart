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
    DateTime lastSeen;
    final raw = json['last_seen'];
    if (raw == null) {
      lastSeen = DateTime.now();
    } else if (raw is int) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is double) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    } else if (raw is String) {
      try {
        lastSeen = DateTime.parse(raw);
      } catch (_) {
        lastSeen = DateTime.fromMillisecondsSinceEpoch(int.tryParse(raw) ?? 0);
      }
    } else {
      lastSeen = DateTime.now();
    }

    return Device(
      name: json['name'] ?? '',
      ip: json['ip'] ?? '',
      lastSeen: lastSeen,
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
