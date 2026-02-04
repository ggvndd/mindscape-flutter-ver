// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_context.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationContextAdapter extends TypeAdapter<ConversationContext> {
  @override
  final int typeId = 0;

  @override
  ConversationContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationContext(
      sessionId: fields[0] as String,
      messages: (fields[1] as List).cast<ChatMessage>(),
      lastUpdated: fields[2] as DateTime,
      metadata: (fields[3] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConversationContext obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.messages)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      content: fields[0] as String,
      isBot: fields[1] as bool,
      timestamp: fields[2] as DateTime,
      isQuickEntry: fields[3] as bool,
      metadata: (fields[4] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.isBot)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isQuickEntry)
      ..writeByte(4)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
