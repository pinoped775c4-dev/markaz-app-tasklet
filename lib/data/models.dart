/// نماذج البيانات الأساسية لتطبيق مركز السنة
library;

class Admin {
  final int? id;
  final String username;
  final String password;
  Admin({this.id, required this.username, required this.password});
  Map<String, dynamic> toMap() => {'id': id, 'username': username, 'password': password};
  factory Admin.fromMap(Map<String, dynamic> m) =>
      Admin(id: m['id'] as int?, username: m['username'] as String, password: m['password'] as String);
}

class Teacher {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String createdAt;
  Teacher({this.id, required this.name, required this.username, required this.password, required this.createdAt});
  Map<String, dynamic> toMap() => {
        'id': id, 'name': name, 'username': username, 'password': password, 'created_at': createdAt,
      };
  factory Teacher.fromMap(Map<String, dynamic> m) => Teacher(
      id: m['id'] as int?,
      name: m['name'] as String,
      username: m['username'] as String,
      password: m['password'] as String,
      createdAt: m['created_at'] as String);
}

class Student {
  final int? id;
  final String name;
  final String phone;
  final String trackId;
  final String createdAt;
  Student({this.id, required this.name, required this.phone, required this.trackId, required this.createdAt});
  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'phone': phone, 'track_id': trackId, 'created_at': createdAt};
  factory Student.fromMap(Map<String, dynamic> m) => Student(
      id: m['id'] as int?,
      name: m['name'] as String,
      phone: m['phone'] as String ?? '',
      trackId: m['track_id'] as String,
      createdAt: m['created_at'] as String);
}

/// الدرس: نظم (أبيات) أو نثر (صفحات)
class Lesson {
  final int? id;
  final String trackId;
  final String title;
  final String type; // 'nathm' | 'nathr'
  final int totalUnits;
  final String createdAt;
  Lesson({this.id, required this.trackId, required this.title, required this.type, required this.totalUnits, required this.createdAt});
  bool get isNathm => type == 'nathm';
  String get unitName => isNathm ? 'بيات' : 'صفحات';
  Map<String, dynamic> toMap() => {
        'id': id, 'track_id': trackId, 'title': title, 'type': type,
        'total_units': totalUnits, 'created_at': createdAt,
      };
  factory Lesson.fromMap(Map<String, dynamic> m) => Lesson(
      id: m['id'] as int?,
      trackId: m['track_id'] as String,
      title: m['title'] as String,
      type: m['type'] as String,
      totalUnits: m['total_units'] as int,
      createdAt: m['created_at'] as String);
}

/// تسجيل يومي للدرس: من وحدة كذا إلى وحدة كذا، بتاريخ وزمن
class LessonEntry {
  final int? id;
  final int lessonId;
  final String date; // yyyy-MM-dd
  final String timeFrom;
  final String timeTo;
  final int fromUnit;
  final int toUnit;
  final String createdAt;
  LessonEntry({this.id, required this.lessonId, required this.date, required this.timeFrom,
      required this.timeTo, required this.fromUnit, required this.toUnit, required this.createdAt});
  int get unitsCount => toUnit - fromUnit + 1;
  Map<String, dynamic> toMap() => {
        'id': id, 'lesson_id': lessonId, 'date': date, 'time_from': timeFrom, 'time_to': timeTo,
        'from_unit': fromUnit, 'to_unit': toUnit, 'created_at': createdAt,
      };
  factory LessonEntry.fromMap(Map<String, dynamic> m) => LessonEntry(
      id: m['id'] as int?,
      lessonId: m['lesson_id'] as int,
      date: m['date'] as String,
      timeFrom: m['time_from'] as String,
      timeTo: m['time_to'] as String,
      fromUnit: m['from_unit'] as int,
      toUnit: m['to_unit'] as int,
      createdAt: m['created_at'] as String);
}

/// المتن المسند للطالب داخل مسار
class Matn {
  final int? id;
  final int studentId;
  final String trackId;
  final String name;
  final String type; // 'nathm' | 'nathr'
  final int totalUnits;
  final String createdAt;
  Matn({this.id, required this.studentId, required this.trackId, required this.name,
      required this.type, required this.totalUnits, required this.createdAt});
  bool get isNathm => type == 'nathm';
  String get unitName => isNathm ? 'أبيات' : 'صفحات';
  Map<String, dynamic> toMap() => {
        'id': id, 'student_id': studentId, 'track_id': trackId, 'name': name,
        'type': type, 'total_units': totalUnits, 'created_at': createdAt,
      };
  factory Matn.fromMap(Map<String, dynamic> m) => Matn(
      id: m['id'] as int?,
      studentId: m['student_id'] as int,
      trackId: m['track_id'] as String,
      name: m['name'] as String,
      type: m['type'] as String,
      totalUnits: m['total_units'] as int,
      createdAt: m['created_at'] as String);
}

/// تسجيل تسميع (سماع) للطالب: من — إلى
class TasmeeRecord {
  final int? id;
  final int matnId;
  final String date;
  final int fromUnit;
  final int toUnit;
  final String createdAt;
  TasmeeRecord({this.id, required this.matnId, required this.date,
      required this.fromUnit, required this.toUnit, required this.createdAt});
  int get unitsCount => toUnit - fromUnit + 1;
  Map<String, dynamic> toMap() => {
        'id': id, 'matn_id': matnId, 'date': date,
        'from_unit': fromUnit, 'to_unit': toUnit, 'created_at': createdAt,
      };
  factory TasmeeRecord.fromMap(Map<String, dynamic> m) => TasmeeRecord(
      id: m['id'] as int?,
      matnId: m['matn_id'] as int,
      date: m['date'] as String,
      fromUnit: m['from_unit'] as int,
      toUnit: m['to_unit'] as int,
      createdAt: m['created_at'] as String);
}

/// ورد قرآني للطالب داخل مسار: من صفحة إلى صفحة
class QuranRecord {
  final int? id;
  final int studentId;
  final String trackId;
  final String date;
  final int fromPage;
  final int toPage;
  final String createdAt;
  QuranRecord({this.id, required this.studentId, required this.trackId, required this.date,
      required this.fromPage, required this.toPage, required this.createdAt});
  int get pagesCount => toPage - fromPage + 1;
  Map<String, dynamic> toMap() => {
        'id': id, 'student_id': studentId, 'track_id': trackId, 'date': date,
        'from_page': fromPage, 'to_page': toPage, 'created_at': createdAt,
      };
  factory QuranRecord.fromMap(Map<String, dynamic> m) => QuranRecord(
      id: m['id'] as int?,
      studentId: m['student_id'] as int,
      trackId: m['track_id'] as String,
      date: m['date'] as String,
      fromPage: m['from_page'] as int,
      toPage: m['to_page'] as int,
      createdAt: m['created_at'] as String);
}
