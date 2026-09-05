import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../core/constants.dart';
import '../state/app_state.dart';
import '../services/backup_service.dart';
import '../widgets/helpers.dart';
import '../widgets/progress_pie.dart';

/// الصفحة الرئيسية للإدارة: تقارير يومية، إدارة المعلمين، مزامنة/نسخ احتياطي
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pages = [
      const DailyReportsTab(),
      const TeachersTab(),
      const BackupTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset('assets/logo.webp', fit: BoxFit.contain),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: state.logout, tooltip: 'خروج'),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.assessment), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.people), label: 'المعلمون'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'المزامنة'),
        ],
      ),
    );
  }
}

/// التقارير اليومية مع المخططات الدائرية
class DailyReportsTab extends StatefulWidget {
  const DailyReportsTab({super.key});
  @override
  State<DailyReportsTab> createState() => _DailyReportsTabState();
}

class _DailyReportsTabState extends State<DailyReportsTab> {
  String date = DateUtilsX.today();
  DayReport? report;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    report = await buildDayReport(date);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final r = report!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(DateUtilsX.formatArabic(date)),
              onPressed: () async {
                final d = await DateUtilsX.pickDate(context, initial: date);
                if (d != null) { setState(() => date = d); await _load(); }
              },
            ),
          ),
        ]),
        const SizedBox(height: 8),

        // ===== قسم الدروس =====
        const _SectionTitle('تقرير الدروس'),
        if (r.lessonEntries.isEmpty)
          const _Empty('لا تسجيلات دروس في هذا اليوم'),
        for (var i = 0; i < r.lessonEntries.length; i++) _lessonReportCard(r, i),

        // ===== قسم المتون =====
        const _SectionTitle('تقرير المتون (لكل طالب)'),
        if (r.tasmee.isEmpty) const _Empty('لا تسميع في هذا اليوم'),
        for (var i = 0; i < r.tasmee.length; i++) _tasmeeReportCard(r, i),

        // ===== قسم القرآن =====
        const _SectionTitle('تقرير الورد القرآني'),
        if (r.quran.isEmpty) const _Empty('لا ورد قرآني في هذا اليوم'),
        ...r.quran.map((q) {
          final s = r.students.where((st) => st.id == q.studentId).firstOrNull;
          return Card(child: ListTile(
            leading: const Icon(Icons.book, color: Colors.green),
            title: Text(s?.name ?? 'طالب'),
            subtitle: Text('${Tracks.name(q.trackId)}: من صفحة ${q.fromPage} إلى صفحة ${q.toPage} (${q.pagesCount} صفحة)'),
          ));
        }),
      ],
    );
  }

  Widget _lessonReportCard(DayReport r, int i) {
    final e = r.lessonEntries[i];
    final lesson = r.lessonsOfEntries[i];
    // نسبة إنجاز اليوم = وحدات اليوم مقابل إجمالي الدرس، ونسبة تراكمية لكل تسجيلات الدرس
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          ListTile(
            dense: true,
            title: Text('${lesson.title} — ${Tracks.name(lesson.trackId)}'),
            subtitle: Text('${lesson.isNathm ? 'نظم' : 'نثر'}: سُجل اليوم من ${e.fromUnit} إلى ${e.toUnit} '
                '(${e.unitsCount} ${lesson.unitName}) — الزمن ${e.timeFrom} — ${e.timeTo}'),
          ),
          FutureBuilder<Progress>(
            future: _lessonProgress(lesson),
            builder: (ctx, snap) => snap.hasData
                ? ProgressPie(done: snap.data!.done, total: snap.data!.total, label: 'إنجاز الدرس كاملاً')
                : const CircularProgressIndicator(),
          ),
        ]),
      ),
    );
  }

  Future<Progress> _lessonProgress(Lesson lesson) async {
    final all = await DB.lessonEntries(lessonId: lesson.id);
    return lessonProgress(lesson, all);
  }

  Widget _tasmeeReportCard(DayReport r, int i) {
    final t = r.tasmee[i];
    final m = r.matnsOfTasmee[i];
    final student = r.students.where((s) => s.id == m.studentId).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          ListTile(
            dense: true,
            title: Text('${student?.name ?? 'طالب'} — ${m.name} (${Tracks.name(m.trackId)})'),
            subtitle: Text('${m.isNathm ? 'نظم' : 'نثر'}: سُمع اليوم من ${t.fromUnit} إلى ${t.toUnit} (${t.unitsCount} ${m.unitName})'),
          ),
          FutureBuilder<Progress>(
            future: _matnProgress(m),
            builder: (ctx, snap) => snap.hasData
                ? ProgressPie(done: snap.data!.done, total: snap.data!.total, label: 'إنجاز المتن')
                : const CircularProgressIndicator(),
          ),
        ]),
      ),
    );
  }

  Future<Progress> _matnProgress(Matn m) async {
    final all = await DB.tasmeeRecords(matnId: m.id);
    return matnProgress(m, all);
  }
}

/// إدارة حسابات المعلمين
class TeachersTab extends StatefulWidget {
  const TeachersTab({super.key});
  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  List<Teacher> teachers = [];

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    teachers = await DB.teachers();
    if (mounted) setState(() {});
  }

  Future<void> _addTeacher() async {
    final nameCtl = TextEditingController();
    final userCtl = TextEditingController();
    final passCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة معلم'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl,
              decoration: const InputDecoration(labelText: 'اسم المعلم', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: userCtl,
              decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: passCtl, obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    if (nameCtl.text.trim().isEmpty || userCtl.text.trim().isEmpty || passCtl.text.isEmpty) {
      if (mounted) snack(context, 'أكمل جميع الحقول'); return;
    }
    try {
      await DB.insertTeacher(Teacher(
        name: nameCtl.text.trim(), username: userCtl.text.trim(), password: passCtl.text,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await _reload();
    } catch (e) {
      if (mounted) snack(context, 'اسم المستخدم مستخدم مسبقاً');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('إضافة معلم (ينشئ حساباً يدخل منه)'),
          onPressed: _addTeacher,
        ),
        const SizedBox(height: 12),
        ...teachers.map((t) => Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF00695C)),
            title: Text(t.name),
            subtitle: Text('اسم المستخدم: ${t.username}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (await confirmDialog(context, 'حذف حساب المعلم ${t.name}؟')) {
                  await DB.deleteTeacher(t.id!);
                  await _reload();
                }
              },
            ),
          ),
        )),
        if (teachers.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا معلمين بعد'))),
      ],
    );
  }
}

/// المزامنة: تصدير النسخة وإرسالها للإدارة، أو استيراد نسخة
class BackupTab extends StatefulWidget {
  const BackupTab({super.key});
  @override
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  bool busy = false;
  String message = '';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('كيف تصل البيانات للإدارة؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('التطبيق يعمل بدون إنترنت بالكامل. عند توفر الاتصال: '
                'اضغط «تصدير ومشاركة النسخة» في جهاز المعلم، وسيُنشأ ملف JSON واحد بكل السجلات، '
                'أرسله عبر أي وسيلة (واتساب، بريد...)، ثم افتحه في جهاز الإدارة بضغطة «استيراد نسخة».'),
            const SizedBox(height: 16),
            if (busy) const Center(child: CircularProgressIndicator()),
            if (!busy) ...[
              FilledButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('تصدير ومشاركة النسخة'),
                onPressed: () async {
                  setState(() => busy = true);
                  try { await BackupService.shareBackup(); }
                  catch (e) { if (mounted) snack(context, 'خطأ في التصدير: $e'); }
                  if (mounted) setState(() => busy = false);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('استيراد نسخة (لجهاز الإدارة)'),
                onPressed: _import,
              ),
            ],
            if (message.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(message, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          ]),
        )),
      ],
    );
  }

  Future<void> _import() async {
    // استيراد عبر لصق محتوى الملف: يضمن العمل على كل الأجهزة بدون إضافات
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد نسخة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('افتح ملف النسخة بأي محرر نصوص، انسخ محتواه كاملاً والصقه هنا:'),
          const SizedBox(height: 10),
          SizedBox(height: 150, child: TextField(
            controller: ctl, maxLines: null, expands: true,
            decoration: const InputDecoration(hintText: 'الصق محتوى JSON هنا', border: OutlineInputBorder()),
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استيراد')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final msg = await BackupService.importFromText(ctl.text);
      setState(() => message = msg);
    } catch (e) {
      setState(() => message = '');
      if (mounted) snack(context, 'تعذر الاستيراد — تأكد من لصق المحتوى كاملاً');
    }
    if (mounted) setState(() => busy = false);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF00695C))),
  );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: const TextStyle(color: Colors.grey)),
  );
}

extension FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
