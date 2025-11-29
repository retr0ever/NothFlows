// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatternConditionsAdapter extends TypeAdapter<PatternConditions> {
  @override
  final int typeId = 15;

  @override
  PatternConditions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatternConditions(
      hours: (fields[0] as List?)?.cast<int>(),
      daysOfWeek: (fields[1] as List?)?.cast<String>(),
      timeOfDay: fields[2] as String?,
      ambientLight: fields[3] as String?,
      deviceMotion: fields[4] as String?,
      previousModeId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatternConditions obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hours)
      ..writeByte(1)
      ..write(obj.daysOfWeek)
      ..writeByte(2)
      ..write(obj.timeOfDay)
      ..writeByte(3)
      ..write(obj.ambientLight)
      ..writeByte(4)
      ..write(obj.deviceMotion)
      ..writeByte(5)
      ..write(obj.previousModeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternConditionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitPatternAdapter extends TypeAdapter<HabitPattern> {
  @override
  final int typeId = 11;

  @override
  HabitPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitPattern(
      id: fields[0] as String,
      modeId: fields[1] as String,
      patternType: fields[2] as String,
      description: fields[3] as String,
      confidence: fields[4] as double,
      occurrences: fields[5] as int,
      conditions: fields[6] as PatternConditions?,
      detectedAt: fields[7] as DateTime,
      lastSeen: fields[8] as DateTime,
      status: fields[9] as PatternStatus,
      llmRationale: fields[10] as String?,
      acceptedCount: fields[11] as int,
      rejectedCount: fields[12] as int,
      ignoredCount: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HabitPattern obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.modeId)
      ..writeByte(2)
      ..write(obj.patternType)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.occurrences)
      ..writeByte(6)
      ..write(obj.conditions)
      ..writeByte(7)
      ..write(obj.detectedAt)
      ..writeByte(8)
      ..write(obj.lastSeen)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.llmRationale)
      ..writeByte(11)
      ..write(obj.acceptedCount)
      ..writeByte(12)
      ..write(obj.rejectedCount)
      ..writeByte(13)
      ..write(obj.ignoredCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternStatusAdapter extends TypeAdapter<PatternStatus> {
  @override
  final int typeId = 14;

  @override
  PatternStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PatternStatus.pending;
      case 1:
        return PatternStatus.active;
      case 2:
        return PatternStatus.accepted;
      case 3:
        return PatternStatus.dismissed;
      case 4:
        return PatternStatus.blocked;
      default:
        return PatternStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PatternStatus obj) {
    switch (obj) {
      case PatternStatus.pending:
        writer.writeByte(0);
        break;
      case PatternStatus.active:
        writer.writeByte(1);
        break;
      case PatternStatus.accepted:
        writer.writeByte(2);
        break;
      case PatternStatus.dismissed:
        writer.writeByte(3);
        break;
      case PatternStatus.blocked:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
