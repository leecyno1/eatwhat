// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferenceAdapter extends TypeAdapter<UserPreference> {
  @override
  final int typeId = 4;

  @override
  UserPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreference(
      id: fields[0] as String?,
      userId: fields[1] as String,
      likedBubbles: (fields[2] as List?)?.cast<String>(),
      dislikedBubbles: (fields[3] as List?)?.cast<String>(),
      ignoredBubbles: (fields[4] as List?)?.cast<String>(),
      bubbleInteractionCount: (fields[5] as Map?)?.cast<String, int>(),
      lastUpdated: fields[6] as DateTime?,
      bubbleWeights: (fields[7] as Map?)?.cast<String, double>(),
      favoriteFoods: (fields[8] as List?)?.cast<String>(),
      dislikedFoods: (fields[9] as List?)?.cast<String>(),
      cuisinePreferences: (fields[10] as Map?)?.cast<String, double>(),
      tastePreferences: (fields[11] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserPreference obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.likedBubbles)
      ..writeByte(3)
      ..write(obj.dislikedBubbles)
      ..writeByte(4)
      ..write(obj.ignoredBubbles)
      ..writeByte(5)
      ..write(obj.bubbleInteractionCount)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.bubbleWeights)
      ..writeByte(8)
      ..write(obj.favoriteFoods)
      ..writeByte(9)
      ..write(obj.dislikedFoods)
      ..writeByte(10)
      ..write(obj.cuisinePreferences)
      ..writeByte(11)
      ..write(obj.tastePreferences);
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
