// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageEventAdapter extends TypeAdapter<UsageEvent> {
  @override
  final int typeId = 10;

  @override
  UsageEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageEvent(
      id: fields[0] as String,
      modeId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      timeOfDay: fields[3] as String,
      hourOfDay: fields[4] as int,
      dayOfWeek: fields[5] as String,
      ambientLight: fields[6] as String?,
      deviceMotion: fields[7] as String?,
      triggerSource: fields[8] as String,
      flowActions: (fields[9] as List?)?.cast<String>(),
      isActivation: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UsageEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.modeId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.timeOfDay)
      ..writeByte(4)
      ..write(obj.hourOfDay)
      ..writeByte(5)
      ..write(obj.dayOfWeek)
      ..writeByte(6)
      ..write(obj.ambientLight)
      ..writeByte(7)
      ..write(obj.deviceMotion)
      ..writeByte(8)
      ..write(obj.triggerSource)
      ..writeByte(9)
      ..write(obj.flowActions)
      ..writeByte(10)
      ..write(obj.isActivation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
