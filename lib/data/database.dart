import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

/// قاعدة بيانات محلية (تعمل بدون إنترنت بالكامل)
class DB {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(p.join(dir, 'markaz_alsunna.db'), version: 1,
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
      await db.execute('CREATE TABLE teachers(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT, username TEXT UNIQUE, password TEXT, created_at TEXT)');
      await db.execute('CREATE TABLE students(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT, phone TEXT, track_id TEXT, created_at TEXT)');
      await db.execute('CREATE TABLE lessons(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'track_id TEXT, title TEXT, type TEXT, total_units INTEGER, created_at TEXT)');
      await db.execute('CREATE TABLE lesson_entries(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'lesson_id INTEGER, date TEXT, time_from TEXT, time_to TEXT, '
          'from_unit INTEGER, to_unit INTEGER, created_at TEXT)');
      await db.execute('CREATE TABLE matns(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'student_id INTEGER, track_id TEXT, name TEXT, type TEXT, total_units INTEGER, created_at TEXT)');
      await db.execute('CREATE TABLE tasmee_records(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'matn_id INTEGER, date TEXT, from_unit INTEGER, to_unit INTEGER, created_at TEXT)');
      await db.execute('CREATE TABLE quran_records(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'student_id INTEGER, track_id TEXT, date TEXT, from_page INTEGER, to_page INTEGER, created_at TEXT)');
    });
  }

  // ---------- إعدادات عامة ----------
  static Future<String?> getSetting(String key) async {
    final db = await instance;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await instance;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- المعلمون ----------
  static Future<List<Teacher>> teachers() async {
    final db = await instance;
    final rows = await db.query('teachers', orderBy: 'id DESC');
    return rows.map(Teacher.fromMap).toList();
  }

  static Future<Teacher?> teacherLogin(String username, String password) async {
    final db = await instance;
    final rows = await db.query('teachers',
        where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return rows.isEmpty ? null : Teacher.fromMap(rows.first);
  }

  static Future<int> insertTeacher(Teacher t) async =>
      (await instance).insert('teachers', t.toMap());

  static Future<int> deleteTeacher(int id) async =>
      (await instance).delete('teachers', where: 'id = ?', whereArgs: [id]);

  // ---------- الطلاب ----------
  static Future<List<Student>> students({String? trackId}) async {
    final db = await instance;
    final rows = trackId == null
        ? await db.query('students', orderBy: 'name')
        : await db.query('students', where: 'track_id = ?', whereArgs: [trackId], orderBy: 'name');
    return rows.map(Student.fromMap).toList();
  }

  static Future<Student?> studentById(int id) async {
    final db = await instance;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  static Future<int> insertStudent(Student s) async =>
      (await instance).insert('students', s.toMap());

  static Future<int> deleteStudent(int id) async {
    final db = await instance;
    await db.delete('matns', where: 'student_id = ?', whereArgs: [id]);
    await db.delete('quran_records', where: 'student_id = ?', whereArgs: [id]);
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- الدروس ----------
  static Future<List<Lesson>> lessons({String? trackId}) async {
    final db = await instance;
    final rows = trackId == null
        ? await db.query('lessons', orderBy: 'id DESC')
        : await db.query('lessons', where: 'track_id = ?', whereArgs: [trackId], orderBy: 'id DESC');
    return rows.map(Lesson.fromMap).toList();
  }

  static Future<Lesson?> lessonById(int id) async {
    final db = await instance;
    final rows = await db.query('lessons', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Lesson.fromMap(rows.first);
  }

  static Future<int> insertLesson(Lesson l) async =>
      (await instance).insert('lessons', l.toMap());

  static Future<int> deleteLesson(int id) async {
    final db = await instance;
    await db.delete('lesson_entries', where: 'lesson_id = ?', whereArgs: [id]);
    return db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- تسجيلات الدروس اليومية ----------
  static Future<List<LessonEntry>> lessonEntries({int? lessonId, String? date}) async {
    final db = await instance;
    final where = <String>[];
    final args = <dynamic>[];
    if (lessonId != null) { where.add('lesson_id = ?'); args.add(lessonId); }
    if (date != null) { where.add('date = ?'); args.add(date); }
    final rows = await db.query('lesson_entries',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC');
    return rows.map(LessonEntry.fromMap).toList();
  }

  static Future<int> insertLessonEntry(LessonEntry e) async =>
      (await instance).insert('lesson_entries', e.toMap());

  static Future<int> deleteLessonEntry(int id) async =>
      (await instance).delete('lesson_entries', where: 'id = ?', whereArgs: [id]);

  // ---------- المتون ----------
  static Future<List<Matn>> matns({int? studentId, String? trackId}) async {
    final db = await instance;
    final where = <String>[];
    final args = <dynamic>[];
    if (studentId != null) { where.add('student_id = ?'); args.add(studentId); }
    if (trackId != null) { where.add('track_id = ?'); args.add(trackId); }
    final rows = await db.query('matns',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args, orderBy: 'id DESC');
    return rows.map(Matn.fromMap).toList();
  }

  static Future<Matn?> matnById(int id) async {
    final db = await instance;
    final rows = await db.query('matns', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Matn.fromMap(rows.first);
  }

  static Future<int> insertMatn(Matn m) async => (await instance).insert('matns', m.toMap());

  static Future<int> deleteMatn(int id) async {
    final db = await instance;
    await db.delete('tasmee_records', where: 'matn_id = ?', whereArgs: [id]);
    return db.delete('matns', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- التسميع ----------
  static Future<List<TasmeeRecord>> tasmeeRecords({int? matnId, String? date}) async {
    final db = await instance;
    final where = <String>[];
    final args = <dynamic>[];
    if (matnId != null) { where.add('matn_id = ?'); args.add(matnId); }
    if (date != null) { where.add('date = ?'); args.add(date); }
    final rows = await db.query('tasmee_records',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args, orderBy: 'date DESC, id DESC');
    return rows.map(TasmeeRecord.fromMap).toList();
  }

  static Future<int> insertTasmee(TasmeeRecord r) async =>
      (await instance).insert('tasmee_records', r.toMap());

  static Future<int> deleteTasmee(int id) async =>
      (await instance).delete('tasmee_records', where: 'id = ?', whereArgs: [id]);

  // ---------- القرآن ----------
  static Future<List<QuranRecord>> quranRecords({int? studentId, String? trackId, String? date}) async {
    final db = await instance;
    final where = <String>[];
    final args = <dynamic>[];
    if (studentId != null) { where.add('student_id = ?'); args.add(studentId); }
    if (trackId != null) { where.add('track_id = ?'); args.add(trackId); }
    if (date != null) { where.add('date = ?'); args.add(date); }
    final rows = await db.query('quran_records',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args, orderBy: 'date DESC, id DESC');
    return rows.map(QuranRecord.fromMap).toList();
  }

  static Future<int> insertQuranRecord(QuranRecord r) async =>
      (await instance).insert('quran_records', r.toMap());

  static Future<int> deleteQuranRecord(int id) async =>
      (await instance).delete('quran_records', where: 'id = ?', whereArgs: [id]);
}
