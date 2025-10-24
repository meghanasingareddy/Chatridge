import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject {

  Message({
    required this.id,
    required this.username,
    required this.text,
    this.target,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
    this.isLocal = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: json['username'] ?? '',
      text: json['text'] ?? '',
      target: json['target'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      attachmentUrl: json['attachment_url'],
      attachmentName: json['attachment_name'],
      attachmentType: json['attachment_type'],
    );
  }
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String text;

  @HiveField(3)
  String? target;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String? attachmentUrl;

  @HiveField(6)
  String? attachmentName;

  @HiveField(7)
  String? attachmentType;

  @HiveField(8)
  bool isLocal;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'text': text,
      'target': target,
      'timestamp': timestamp.toIso8601String(),
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType,
    };
  }

  bool get isPrivate => target != null && target!.isNotEmpty;

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get isImage => attachmentType?.startsWith('image/') ?? false;

  bool get isDocument => !isImage && hasAttachment;
}
