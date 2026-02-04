// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 2;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      moodType: fields[1] as MoodType,
      description: fields[2] as String?,
      timestamp: fields[3] as DateTime,
      context: (fields[4] as Map?)?.cast<String, dynamic>(),
      isQuickEntry: fields[5] as bool,
      contextTags: (fields[6] as List).cast<String>(),
      location: fields[7] as LocationContext?,
      activity: fields[8] as String?,
      stressLevel: fields[9] as int?,
      energyLevel: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.moodType)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.context)
      ..writeByte(5)
      ..write(obj.isQuickEntry)
      ..writeByte(6)
      ..write(obj.contextTags)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.activity)
      ..writeByte(9)
      ..write(obj.stressLevel)
      ..writeByte(10)
      ..write(obj.energyLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationContextAdapter extends TypeAdapter<LocationContext> {
  @override
  final int typeId = 4;

  @override
  LocationContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationContext(
      type: fields[0] as String,
      name: fields[1] as String?,
      latitude: fields[2] as double?,
      longitude: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationContext obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
