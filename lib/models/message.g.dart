// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      username: fields[1] as String,
      text: fields[2] as String,
      target: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      attachmentUrl: fields[5] as String?,
      attachmentName: fields[6] as String?,
      attachmentType: fields[7] as String?,
      isLocal: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.target)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.attachmentUrl)
      ..writeByte(6)
      ..write(obj.attachmentName)
      ..writeByte(7)
      ..write(obj.attachmentType)
      ..writeByte(8)
      ..write(obj.isLocal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
