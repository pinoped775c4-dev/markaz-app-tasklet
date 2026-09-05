import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../core/constants.dart';
import '../state/app_state.dart';
import '../services/backup_service.dart';
import '../widgets/helpers.dart';
import '../widgets/design.dart';
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
        backgroundColor: WColors.wa,
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('لوحة الإدارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('مركز السنة للعلوم الشرعية',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
        ]),
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
          NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'المعلمون'),
          NavigationDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync), label: 'المزامنة'),
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
  int teachersCount = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    report = await buildDayReport(date);
    final t = await DB.teachers();
    teachersCount = t.length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: WColors.wa2));
    final r = report!;
    final todayRecords = r.lessonEntries.length + r.tasmee.length + r.quran.length;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ===== شريط الإحصائيات =====
        Row(children: [
          WStatCard(value: '$teachersCount', label: 'معلم'),
          const SizedBox(width: 10),
          WStatCard(value: '${r.students.length}', label: 'طالب'),
          const SizedBox(width: 10),
          WStatCard(value: '$todayRecords', label: 'تسجيل اليوم'),
        ]),
        const SizedBox(height: 14),

        // ===== اختيار التاريخ =====
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final d = await DateUtilsX.pickDate(context, initial: date);
              if (d != null) { setState(() => date = d); await _load(); }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WColors.lightGreenBg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_month, color: WColors.wa, size: 20),
                ),
                const SizedBox(width: 12),
                Text('تقرير يوم ${DateUtilsX.formatArabic(date)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: WColors.txt)),
                const Spacer(),
                const Icon(Icons.expand_more, color: WColors.sub),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ===== قسم الدروس =====
        WSectionCard(
          title: 'تقرير الدروس',
          icon: Icons.menu_book,
          children: [
            if (r.lessonEntries.isEmpty) const WEmpty('لا تسجيلات دروس في هذا اليوم'),
            for (var i = 0; i < r.lessonEntries.length; i++)
              _lessonReportCard(r, i),
          ],
        ),

        // ===== قسم المتون =====
        WSectionCard(
          title: 'تقرير المتون (لكل طالب)',
          icon: Icons.record_voice_over,
          children: [
            if (r.tasmee.isEmpty) const WEmpty('لا تسميع في هذا اليوم'),
            for (var i = 0; i < r.tasmee.length; i++) _tasmeeReportCard(r, i),
          ],
        ),

        // ===== قسم القرآن =====
        WSectionCard(
          title: 'تقرير الورد القرآني',
          icon: Icons.auto_stories,
          children: [
            if (r.quran.isEmpty) const WEmpty('لا ورد قرآني في هذا اليوم'),
            for (final q in r.quran)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9EDEF)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: WColors.lightGreenBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.book, color: WColors.wa, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.students.where((st) => st.id == q.studentId).firstOrNull?.name ?? 'طالب',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: WColors.txt)),
                      const SizedBox(height: 3),
                      Text('${Tracks.name(q.trackId)}: من صفحة ${q.fromPage} إلى صفحة ${q.toPage} (${q.pagesCount} صفحة)',
                          style: const TextStyle(fontSize: 12.5, color: WColors.sub)),
                    ]),
                  ),
                ]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _lessonReportCard(DayReport r, int i) {
    final e = r.lessonEntries[i];
    final lesson = r.lessonsOfEntries[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDEF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(lesson.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: WColors.txt))),
          WChip(Tracks.name(lesson.trackId), color: WColors.wa),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 6, children: [
          WChip(lesson.isNathm ? 'نظم' : 'نثر', color: WColors.wa2),
          WChip('${e.unitsCount} ${lesson.unitName} اليوم', color: Colors.brown),
        ]),
        const SizedBox(height: 6),
        Text('سُجل اليوم من ${e.fromUnit} إلى ${e.toUnit} — الزمن ${e.timeFrom} — ${e.timeTo}',
            style: const TextStyle(fontSize: 12.5, color: WColors.sub)),
        const Divider(height: 18),
        FutureBuilder<Progress>(
          future: _lessonProgress(lesson),
          builder: (ctx, snap) => snap.hasData
              ? ProgressPie(done: snap.data!.done, total: snap.data!.total, label: 'إنجاز الدرس كاملاً')
              : const Center(child: CircularProgressIndicator(color: WColors.wa2)),
        ),
      ]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDEF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: WColors.wa2,
            child: Text((student?.name.isNotEmpty == true ? student!.name.substring(0, 1) : '؟'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('${student?.name ?? 'طالب'} — ${m.name}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: WColors.txt))),
          WChip(Tracks.name(m.trackId), color: WColors.wa),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          WChip(m.isNathm ? 'نظم' : 'نثر', color: WColors.wa2),
          WChip('${t.unitsCount} ${m.unitName} اليوم', color: Colors.brown),
        ]),
        const SizedBox(height: 6),
        Text('سُمع اليوم من ${t.fromUnit} إلى ${t.toUnit}',
            style: const TextStyle(fontSize: 12.5, color: WColors.sub)),
        const Divider(height: 18),
        FutureBuilder<Progress>(
          future: _matnProgress(m),
          builder: (ctx, snap) => snap.hasData
              ? ProgressPie(done: snap.data!.done, total: snap.data!.total, label: 'إنجاز المتن')
              : const Center(child: CircularProgressIndicator(color: WColors.wa2)),
        ),
      ]),
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
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: WColors.wa2, minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.person_add),
          label: const Text('إضافة معلم (ينشئ حساباً يدخل منه)'),
          onPressed: _addTeacher,
        ),
        const SizedBox(height: 12),
        if (teachers.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const WEmpty('لا معلمين بعد — أضف أول حساب معلم بالزر أعلاه'),
          ),
        ...teachers.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x140B141A), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 21,
              backgroundColor: WColors.wa,
              child: Text(t.name.isNotEmpty ? t.name.substring(0, 1) : '؟',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
            ),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, color: WColors.txt)),
            subtitle: Text('اسم المستخدم: ${t.username}',
                style: const TextStyle(fontSize: 12.5, color: WColors.sub)),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x140B141A), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: WColors.lightGreenBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sync, color: WColors.wa, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('كيف تصل البيانات للإدارة؟',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: WColors.txt)),
            ]),
            const SizedBox(height: 10),
            const Text('التطبيق يعمل بدون إنترنت بالكامل. عند توفر الاتصال: '
                'اضغط «تصدير ومشاركة النسخة» في جهاز المعلم، وسيُنشأ ملف JSON واحد بكل السجلات، '
                'أرسله عبر أي وسيلة (واتساب، بريد...)، ثم افتحه في جهاز الإدارة بضغطة «استيراد نسخة».',
                style: TextStyle(fontSize: 13.5, height: 1.7, color: WColors.sub)),
            const SizedBox(height: 16),
            if (busy) const Center(child: CircularProgressIndicator(color: WColors.wa2)),
            if (!busy) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: WColors.wa2, minimumSize: const Size.fromHeight(48)),
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
                style: OutlinedButton.styleFrom(
                    foregroundColor: WColors.wa, minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.download),
                label: const Text('استيراد نسخة (لجهاز الإدارة)'),
                onPressed: _import,
              ),
            ],
            if (message.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: WColors.lightGreenBg, borderRadius: BorderRadius.circular(10)),
                child: Text(message, style: const TextStyle(color: WColors.wa, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
          ]),
        ),
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

extension FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
