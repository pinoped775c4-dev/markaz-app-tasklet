import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../widgets/helpers.dart';
import '../../widgets/progress_pie.dart';

/// قسم المتون: قائمة الطلاب، ولكل طالب صفحة خاصة بمتونه وتسجيل التسميع
class MutunTab extends StatefulWidget {
  final String trackId;
  const MutunTab({super.key, required this.trackId});
  @override
  State<MutunTab> createState() => _MutunTabState();
}

class _MutunTabState extends State<MutunTab> with AutomaticKeepAliveClientMixin {
  List<Student> students = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    students = await DB.students(trackId: widget.trackId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (students.isEmpty) {
      return const Center(child: Text('أضف الطلاب من قسم الدروس أولاً حتى تتابع متونهم هنا'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('اضغط على الطالب لفتح صفحة متونه وتسجيل ما تسمعه من — إلى',
              style: TextStyle(color: Colors.grey)),
        ),
        ...students.map((s) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(s.name.isEmpty ? '?' : s.name[0])),
            title: Text(s.name),
            subtitle: const Text('صفحة المتون والتسميع'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StudentMatnPage(student: s, trackId: widget.trackId)));
              await _reload();
            },
          ),
        )),
      ],
    );
  }
}

/// صفحة الطالب الخاصة في المتون
class StudentMatnPage extends StatefulWidget {
  final Student student;
  final String trackId;
  const StudentMatnPage({super.key, required this.student, required this.trackId});
  @override
  State<StudentMatnPage> createState() => _StudentMatnPageState();
}

class _StudentMatnPageState extends State<StudentMatnPage> {
  List<Matn> matns = [];
  Map<int, List<TasmeeRecord>> records = {};

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    matns = await DB.matns(studentId: widget.student.id);
    records = {};
    for (final m in matns) {
      records[m.id!] = await DB.tasmeeRecords(matnId: m.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addMatn() async {
    final nameCtl = TextEditingController();
    final totalCtl = TextEditingController();
    String type = 'nathm';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('إسناد متن للطالب'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl,
              decoration: const InputDecoration(labelText: 'اسم المتن (نظم/نثر)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
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
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    final name = nameCtl.text.trim();
    final total = int.tryParse(totalCtl.text) ?? 0;
    if (name.isEmpty || total <= 0) { if (mounted) snack(context, 'أدخل اسم المتن والعدد'); return; }
    await DB.insertMatn(Matn(
      studentId: widget.student.id!, trackId: widget.trackId,
      name: name, type: type, totalUnits: total,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }

  Future<void> _addTasmee(Matn matn) async {
    final fromCtl = TextEditingController();
    final toCtl = TextEditingController();
    String date = DateUtilsX.today();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('تسجيل ما سمعه — ${matn.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text('${DateUtilsX.dayName(DateTime.tryParse(date) ?? DateTime.now())} — $date'),
            onPressed: () async {
              final d = await DateUtilsX.pickDate(ctx, initial: date);
              if (d != null) setD(() => date = d);
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: fromCtl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'من ${matn.unitName}', border: const OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: toCtl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'إلى ${matn.unitName}', border: const OutlineInputBorder()))),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    final from = int.tryParse(fromCtl.text), to = int.tryParse(toCtl.text);
    if (from == null || to == null || to < from) { if (mounted) snack(context, 'تحقق من قيم (من — إلى)'); return; }
    await DB.insertTasmee(TasmeeRecord(
      matnId: matn.id!, date: date, fromUnit: from, toUnit: to,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('متون ${widget.student.name}')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('إسناد متن'),
        onPressed: _addMatn,
      ),
      body: matns.isEmpty
          ? const Center(child: Text('لم يُسند لهذا الطالب متن بعد\nاضغط «إسناد متن» للبدء', textAlign: TextAlign.center))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final m in matns) _matnCard(m)],
            ),
    );
  }

  Widget _matnCard(Matn matn) {
    final list = records[matn.id!] ?? [];
    final done = list.fold<int>(0, (s, r) => s + r.unitsCount);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${matn.name} (${matn.isNathm ? 'نظم' : 'نثر'}) — ${matn.totalUnits} ${matn.unitName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  if (await confirmDialog(context, 'حذف المتن وكل تسجيلاته؟')) {
                    await DB.deleteMatn(matn.id!);
                    await _reload();
                  }
                }),
          ]),
          Center(child: ProgressPie(done: done, total: matn.totalUnits, label: 'نسبة ما سُمع')),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.record_voice_over),
            label: const Text('تسجيل سماع (من — إلى)'),
            onPressed: () => _addTasmee(matn),
          ),
          const Divider(height: 20),
          if (list.isEmpty) const Text('لم يُسمع منه شيء بعد'),
          ...list.map((r) => ListTile(
            dense: true,
            leading: const Icon(Icons.hearing, color: Colors.teal),
            title: Text('${DateUtilsX.formatArabic(r.date)} — سُمع من ${r.fromUnit} إلى ${r.toUnit} (${r.unitsCount} ${matn.unitName})'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  await DB.deleteTasmee(r.id!);
                  await _reload();
                }),
          )),
        ]),
      ),
    );
  }
}
