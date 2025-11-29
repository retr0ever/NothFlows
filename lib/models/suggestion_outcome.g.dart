// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_outcome.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SuggestionOutcomeAdapter extends TypeAdapter<SuggestionOutcome> {
  @override
  final int typeId = 13;

  @override
  SuggestionOutcome read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SuggestionOutcome(
      id: fields[0] as String,
      suggestionId: fields[1] as String,
      patternId: fields[2] as String,
      modeId: fields[3] as String,
      outcome: fields[4] as SuggestionOutcomeType,
      timestamp: fields[5] as DateTime,
      reason: fields[6] as String?,
      responseTimeMs: fields[7] as int,
      contextAtTime: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SuggestionOutcome obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.suggestionId)
      ..writeByte(2)
      ..write(obj.patternId)
      ..writeByte(3)
      ..write(obj.modeId)
      ..writeByte(4)
      ..write(obj.outcome)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.responseTimeMs)
      ..writeByte(8)
      ..write(obj.contextAtTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionOutcomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SuggestionOutcomeTypeAdapter extends TypeAdapter<SuggestionOutcomeType> {
  @override
  final int typeId = 16;

  @override
  SuggestionOutcomeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SuggestionOutcomeType.accepted;
      case 1:
        return SuggestionOutcomeType.rejected;
      case 2:
        return SuggestionOutcomeType.ignored;
      case 3:
        return SuggestionOutcomeType.blocked;
      default:
        return SuggestionOutcomeType.accepted;
    }
  }

  @override
  void write(BinaryWriter writer, SuggestionOutcomeType obj) {
    switch (obj) {
      case SuggestionOutcomeType.accepted:
        writer.writeByte(0);
        break;
      case SuggestionOutcomeType.rejected:
        writer.writeByte(1);
        break;
      case SuggestionOutcomeType.ignored:
        writer.writeByte(2);
        break;
      case SuggestionOutcomeType.blocked:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionOutcomeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
