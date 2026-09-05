import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../widgets/helpers.dart';
import '../../widgets/progress_pie.dart';

/// قسم الدروس داخل المسار:
/// - أول مرة: زر إضافة درس (نظم: عدد أبيات / نثر: عدد صفحات)
/// - بعدها: تسجيل يومي (اليوم، من — إلى، التاريخ، الزمن)
/// - جدول تحضير الطلاب المشتركين في المسار
class LessonsTab extends StatefulWidget {
  final String trackId;
  const LessonsTab({super.key, required this.trackId});
  @override
  State<LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<LessonsTab> with AutomaticKeepAliveClientMixin {
  List<Lesson> lessons = [];
  Map<int, List<LessonEntry>> entries = {};
  List<Student> students = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    lessons = await DB.lessons(trackId: widget.trackId);
    students = await DB.students(trackId: widget.trackId);
    entries = {};
    for (final l in lessons) {
      entries[l.id!] = await DB.lessonEntries(lessonId: l.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addLessonDialog() async {
    final titleCtl = TextEditingController();
    final totalCtl = TextEditingController();
    String type = 'nathm';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('إضافة درس'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtl,
              decoration: const InputDecoration(labelText: 'اسم الدرس', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'نوع الدرس', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'nathm', child: Text('نظم')),
              DropdownMenuItem(value: 'nathr', child: Text('نثر')),
            ],
            onChanged: (v) => setD(() => type = v ?? 'nathm'),
          ),
          const SizedBox(height: 12),
          TextField(controller: totalCtl, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                  labelText: type == 'nathm' ? 'عدد الأبيات' : 'عدد الصفحات',
                  border: const OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    final title = titleCtl.text.trim();
    final total = int.tryParse(totalCtl.text) ?? 0;
    if (title.isEmpty || total <= 0) { if (mounted) snack(context, 'أدخل اسم الدرس والعدد صحيحاً'); return; }
    await DB.insertLesson(Lesson(
      trackId: widget.trackId, title: title, type: type, totalUnits: total,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }

  Future<void> _addDailyEntry(Lesson lesson) async {
    final fromCtl = TextEditingController();
    final toCtl = TextEditingController();
    final timeFromCtl = TextEditingController();
    final timeToCtl = TextEditingController();
    String date = DateUtilsX.today();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('تسجيل الدرس اليومي'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text('${DateUtilsX.dayName(DateTime.tryParse(date) ?? DateTime.now())} — $date'),
            onPressed: () async {
              final d = await DateUtilsX.pickDate(ctx, initial: date);
              if (d != null) setD(() => date = d);
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: fromCtl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'من ${lesson.unitName}', border: const OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: toCtl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'إلى ${lesson.unitName}', border: const OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: timeFromCtl,
                decoration: const InputDecoration(labelText: 'الزمن من', hintText: '08:00', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: timeToCtl,
                decoration: const InputDecoration(labelText: 'إلى', hintText: '09:30', border: OutlineInputBorder()))),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    final from = int.tryParse(fromCtl.text), to = int.tryParse(toCtl.text);
    if (from == null || to == null || to < from) { if (mounted) snack(context, 'تحقق من قيم (من — إلى)'); return; }
    await DB.insertLessonEntry(LessonEntry(
      lessonId: lesson.id!, date: date,
      timeFrom: timeFromCtl.text.trim(), timeTo: timeToCtl.text.trim(),
      fromUnit: from, toUnit: to, createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }

  Future<void> _addStudent() async {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طالب'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl,
              decoration: const InputDecoration(labelText: 'اسم الطالب', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: phoneCtl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم التواصل (اختياري)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) { if (mounted) snack(context, 'أدخل اسم الطالب'); return; }
    await DB.insertStudent(Student(
      name: name, phone: phoneCtl.text.trim(), trackId: widget.trackId,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (lessons.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.library_books, size: 60, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('لا يوجد درس بعد'),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('إضافة درس'),
          onPressed: _addLessonDialog,
        ),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final lesson in lessons) ...[
          _lessonCard(lesson),
          const SizedBox(height: 14),
        ],
        _studentsCard(),
      ],
    );
  }

  Widget _lessonCard(Lesson lesson) {
    final list = entries[lesson.id!] ?? [];
    final done = list.fold<int>(0, (s, e) => s + e.unitsCount);
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${lesson.title} (${lesson.isNathm ? 'نظم' : 'نثر'})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  if (await confirmDialog(context, 'حذف الدرس وكل تسجيلاته؟')) {
                    await DB.deleteLesson(lesson.id!);
                    await _reload();
                  }
                }),
          ]),
          Text('الإجمالي المحدد: ${lesson.totalUnits} ${lesson.unitName}'),
          const SizedBox(height: 8),
          Center(child: ProgressPie(done: done, total: lesson.totalUnits, label: 'نسبة الإنجاز')),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.edit_calendar),
            label: const Text('تسجيل اليوم (من — إلى)'),
            onPressed: () => _addDailyEntry(lesson),
          ),
          const Divider(height: 20),
          const Text('التسجيلات:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(6), child: Text('لا تسجيلات بعد')),
          ...list.map((e) => ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('${DateUtilsX.formatArabic(e.date)} — ${lesson.unitName} من ${e.fromUnit} إلى ${e.toUnit}'),
            subtitle: (e.timeFrom.isEmpty && e.timeTo.isEmpty)
                ? null : Text('الزمن: ${e.timeFrom} — ${e.timeTo}'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  await DB.deleteLessonEntry(e.id!);
                  await _reload();
                }),
          )),
        ]),
      ),
    );
  }

  Widget _studentsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('تحضير الطلاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            FilledButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('إضافة طالب'),
              onPressed: _addStudent,
            ),
          ]),
          const SizedBox(height: 8),
          if (students.isEmpty) const Text('لا طلاب بعد — أضف طالباً للبدء'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('اسم الطالب')),
                DataColumn(label: Text('التواصل')),
              ],
              rows: List.generate(students.length, (i) {
                final s = students[i];
                return DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(s.name)),
                  DataCell(Text(s.phone)),
                ]);
              }),
            ),
          ),
        ]),
      ),
    );
  }
}
