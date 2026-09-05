import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database.dart';
import '../data/models.dart';

/// مزامنة/نسخ احتياطي: تصدير كل البيانات كملف JSON
/// وإعادة استيرادها على جهاز الإدارة (يعمل حتى بدون إنترنت،
/// ويمكن إرسال الملف عبر أي وسيلة مشاركة عند توفر الاتصال).
class BackupService {
  static Future<Map<String, dynamic>> exportAll() async {
    final teachers = await DB.teachers();
    final students = await DB.students();
    final lessons = await DB.lessons();
    final entries = await DB.lessonEntries();
    final matns = await DB.matns();
    final tasmee = await DB.tasmeeRecords();
    final quran = await DB.quranRecords();
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'teachers': teachers.map((t) => t.toMap()).toList(),
      'students': students.map((s) => s.toMap()).toList(),
      'lessons': lessons.map((l) => l.toMap()).toList(),
      'lesson_entries': entries.map((e) => e.toMap()).toList(),
      'matns': matns.map((m) => m.toMap()).toList(),
      'tasmee_records': tasmee.map((t) => t.toMap()).toList(),
      'quran_records': quran.map((q) => q.toMap()).toList(),
    };
  }

  static Future<String> exportToFile() async {
    final data = await exportAll();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/markaz_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(data));
    return file.path;
  }

  static Future<void> shareBackup() async {
    final path = await exportToFile();
    await Share.shareXFiles([XFile(path)], text: 'نسخة احتياطية - مركز السنة');
  }

  /// استيراد: يدمج البيانات (يتجاهل المكرر بمعرّفات جديدة)
  static Future<String> importFromText(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    int count = 0;
    for (final t in (data['teachers'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(t as Map)..remove('id');
      await DB.insertTeacher(Teacher.fromMap(m)); count++;
    }
    for (final s in (data['students'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(s as Map)..remove('id');
      await DB.insertStudent(Student.fromMap(m)); count++;
    }
    for (final l in (data['lessons'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(l as Map)..remove('id');
      await DB.insertLesson(Lesson.fromMap(m)); count++;
    }
    // lesson_entries/matns/tasmee/quran تُستورد مع إعادة ربط المعرفات
    final lessonIdMap = <int, int>{};
    final studentIdMap = <int, int>{};
    final matnIdMap = <int, int>{};
    for (final l in (data['lessons'] as List? ?? [])) {
      final orig = (l as Map)['id'] as int;
      final rows = await DB.lessons();
      lessonIdMap[orig] = rows.first.id!;
    }
    for (final s in (data['students'] as List? ?? [])) {
      final orig = (s as Map)['id'] as int;
      final rows = await DB.students();
      studentIdMap[orig] = rows.first.id!;
    }
    for (final m in (data['matns'] as List? ?? [])) {
      final mm = Map<String, dynamic>.from(m as Map);
      final origId = mm.remove('id') as int;
      mm['student_id'] = studentIdMap[mm['student_id']] ?? mm['student_id'];
      final newId = await DB.insertMatn(Matn.fromMap(mm));
      matnIdMap[origId] = newId; count++;
    }
    for (final e in (data['lesson_entries'] as List? ?? [])) {
      final mm = Map<String, dynamic>.from(e as Map)..remove('id');
      mm['lesson_id'] = lessonIdMap[mm['lesson_id']] ?? mm['lesson_id'];
      await DB.insertLessonEntry(LessonEntry.fromMap(mm)); count++;
    }
    for (final t in (data['tasmee_records'] as List? ?? [])) {
      final mm = Map<String, dynamic>.from(t as Map)..remove('id');
      mm['matn_id'] = matnIdMap[mm['matn_id']] ?? mm['matn_id'];
      await DB.insertTasmee(TasmeeRecord.fromMap(mm)); count++;
    }
    for (final q in (data['quran_records'] as List? ?? [])) {
      final mm = Map<String, dynamic>.from(q as Map)..remove('id');
      mm['student_id'] = studentIdMap[mm['student_id']] ?? mm['student_id'];
      await DB.insertQuranRecord(QuranRecord.fromMap(mm)); count++;
    }
    return 'تم استيراد $count سجلاً بنجاح';
  }
}
