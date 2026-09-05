import 'package:flutter/foundation.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../core/constants.dart';

/// حالة التطبيق: الجلسة الحالية + إعادة تحميل البيانات
class AppState extends ChangeNotifier {
  Teacher? teacher; // null = وضع الإدارة
  bool get isAdmin => teacher == null;
  bool adminLoggedIn = false;

  void loginAsTeacher(Teacher t) { teacher = t; notifyListeners(); }
  void loginAsAdmin() { adminLoggedIn = true; notifyListeners(); }
  void logout() { teacher = null; adminLoggedIn = false; notifyListeners(); }
}

/// نموذج بيانات يوم مجمّع للتقارير
class DayReport {
  final String date;
  final List<LessonEntry> lessonEntries;
  final List<Lesson> lessonsOfEntries;
  final List<TasmeeRecord> tasmee;
  final List<Matn> matnsOfTasmee;
  final List<QuranRecord> quran;
  final List<Student> students;
  DayReport({
    required this.date,
    required this.lessonEntries,
    required this.lessonsOfEntries,
    required this.tasmee,
    required this.matnsOfTasmee,
    required this.quran,
    required this.students,
  });
}

/// حساب نسبة الإنجاز (تم/متبقي) لأي عنصر له إجمالي
class Progress {
  final int done;
  final int total;
  Progress(this.done, this.total);
  double get pct => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  int get remaining => (total - done).clamp(0, total);
}

Progress lessonProgress(Lesson lesson, List<LessonEntry> entries) {
  final totalUnits = entries.fold<int>(0, (s, e) => s + e.unitsCount);
  return Progress(totalUnits, lesson.totalUnits);
}

Progress matnProgress(Matn matn, List<TasmeeRecord> records) {
  final done = records.fold<int>(0, (s, r) => s + r.unitsCount);
  return Progress(done, matn.totalUnits);
}

Future<DayReport> buildDayReport(String date) async {
  final entries = await DB.lessonEntries(date: date);
  final lessons = <Lesson>[];
  for (final e in entries) {
    final l = await DB.lessonById(e.lessonId);
    if (l != null) lessons.add(l);
  }
  final tasmee = await DB.tasmeeRecords(date: date);
  final matns = <Matn>[];
  for (final t in tasmee) {
    final m = await DB.matnById(t.matnId);
    if (m != null) matns.add(m);
  }
  final quran = await DB.quranRecords(date: date);
  final students = await DB.students();
  return DayReport(
    date: date,
    lessonEntries: entries,
    lessonsOfEntries: lessons,
    tasmee: tasmee,
    matnsOfTasmee: matns,
    quran: quran,
    students: students,
  );
}

String trackNameOf(String id) => Tracks.name(id);
