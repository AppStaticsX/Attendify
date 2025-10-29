import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  DateTime? firstLaunchDate;

  @HiveField(1)
  List<String>? holidays; // Add this field

  AppSettings({this.firstLaunchDate, this.holidays});
}