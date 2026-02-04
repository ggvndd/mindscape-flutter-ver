// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_context.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserContextAdapter extends TypeAdapter<UserContext> {
  @override
  final int typeId = 5;

  @override
  UserContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserContext(
      userId: fields[0] as String,
      tags: (fields[1] as List).cast<String>(),
      lastUpdated: fields[2] as DateTime,
      behaviorPattern: fields[3] as UserBehaviorPattern,
      preferences: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserContext obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.tags)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.behaviorPattern)
      ..writeByte(4)
      ..write(obj.preferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserBehaviorPatternAdapter extends TypeAdapter<UserBehaviorPattern> {
  @override
  final int typeId = 6;

  @override
  UserBehaviorPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserBehaviorPattern(
      averageMoodScore: fields[0] as double,
      mostActiveHours: (fields[1] as List).cast<int>(),
      preferredInteractionStyle: fields[2] as InteractionStyle,
      commonMoodTriggers: (fields[3] as List).cast<String>(),
      conversationLengthPreference: fields[4] as ConversationLength,
      moodPatterns: (fields[5] as Map).cast<String, double>(),
      lastAnalyzed: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserBehaviorPattern obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.averageMoodScore)
      ..writeByte(1)
      ..write(obj.mostActiveHours)
      ..writeByte(2)
      ..write(obj.preferredInteractionStyle)
      ..writeByte(3)
      ..write(obj.commonMoodTriggers)
      ..writeByte(4)
      ..write(obj.conversationLengthPreference)
      ..writeByte(5)
      ..write(obj.moodPatterns)
      ..writeByte(6)
      ..write(obj.lastAnalyzed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBehaviorPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InteractionStyleAdapter extends TypeAdapter<InteractionStyle> {
  @override
  final int typeId = 7;

  @override
  InteractionStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InteractionStyle.quick;
      case 1:
        return InteractionStyle.balanced;
      case 2:
        return InteractionStyle.detailed;
      default:
        return InteractionStyle.quick;
    }
  }

  @override
  void write(BinaryWriter writer, InteractionStyle obj) {
    switch (obj) {
      case InteractionStyle.quick:
        writer.writeByte(0);
        break;
      case InteractionStyle.balanced:
        writer.writeByte(1);
        break;
      case InteractionStyle.detailed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationLengthAdapter extends TypeAdapter<ConversationLength> {
  @override
  final int typeId = 8;

  @override
  ConversationLength read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConversationLength.short;
      case 1:
        return ConversationLength.medium;
      case 2:
        return ConversationLength.long;
      default:
        return ConversationLength.short;
    }
  }

  @override
  void write(BinaryWriter writer, ConversationLength obj) {
    switch (obj) {
      case ConversationLength.short:
        writer.writeByte(0);
        break;
      case ConversationLength.medium:
        writer.writeByte(1);
        break;
      case ConversationLength.long:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationLengthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
