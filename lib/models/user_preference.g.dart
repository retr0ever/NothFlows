// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferenceAdapter extends TypeAdapter<UserPreference> {
  @override
  final int typeId = 12;

  @override
  UserPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreference(
      id: fields[0] as String,
      preferenceType: fields[1] as String,
      value: fields[2] as String,
      confidence: fields[3] as double,
      learnedAt: fields[4] as DateTime,
      evidenceCount: fields[5] as int,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreference obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.preferenceType)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.learnedAt)
      ..writeByte(5)
      ..write(obj.evidenceCount)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
