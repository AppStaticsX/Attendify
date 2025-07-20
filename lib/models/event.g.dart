// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event()
      ..name = fields[0] as String
      ..conductorName = fields[1] as String
      ..completedDays = (fields[2] as HiveList?)?.castHiveList()
      ..id = fields[3] as int
      ..assignedDays = (fields[4] as List).cast<String>()
      ..notConductedDays = (fields[5] as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.conductorName)
      ..writeByte(2)
      ..write(obj.completedDays)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.assignedDays)
      ..writeByte(5)
      ..write(obj.notConductedDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CompletedDayAdapter extends TypeAdapter<CompletedDay> {
  @override
  final int typeId = 1;

  @override
  CompletedDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedDay(
      date: fields[0] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedDay obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
