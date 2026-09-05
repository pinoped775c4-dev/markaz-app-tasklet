import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../widgets/helpers.dart';

/// قسم القرآن داخل المسار: متابعة الورد القرآني لكل طالب من صفحة إلى صفحة
class QuranTab extends StatefulWidget {
  final String trackId;
  const QuranTab({super.key, required this.trackId});
  @override
  State<QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<QuranTab> with AutomaticKeepAliveClientMixin {
  List<Student> students = [];
  Map<int, List<QuranRecord>> records = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    students = await DB.students(trackId: widget.trackId);
    records = {};
    for (final s in students) {
      records[s.id!] = await DB.quranRecords(studentId: s.id, trackId: widget.trackId);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (students.isEmpty) {
      return const Center(child: Text('أضف الطلاب من قسم الدروس أولاً حتى تتابع ورد قرآنيهم هنا'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final s in students) _studentCard(s),
      ],
    );
  }

  Widget _studentCard(Student s) {
    final list = records[s.id!] ?? [];
    final pages = list.fold<int>(0, (sum, r) => sum + r.pagesCount);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('مجموع الورد المسجل: $pages صفحة'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              icon: const Icon(Icons.auto_stories),
              label: const Text('تسجيل ورد (من صفحة — إلى صفحة)'),
              onPressed: () => _addRecord(s),
            ),
          ),
          ...list.map((r) => ListTile(
            dense: true,
            leading: const Icon(Icons.book, color: Colors.green),
            title: Text('${DateUtilsX.formatArabic(r.date)} — من صفحة ${r.fromPage} إلى صفحة ${r.toPage}'),
            subtitle: Text('(${r.pagesCount} صفحة)'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  await DB.deleteQuranRecord(r.id!);
                  await _reload();
                }),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _addRecord(Student s) async {
    final fromCtl = TextEditingController();
    final toCtl = TextEditingController();
    String date = DateUtilsX.today();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('ورد ${s.name} القرآني'),
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
                decoration: const InputDecoration(labelText: 'من صفحة', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: toCtl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'إلى صفحة', border: OutlineInputBorder()))),
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
    if (from == null || to == null || to < from || to > 604) { if (mounted) snack(context, 'تحقق من أرقام الصفحات (1 — 604)'); return; }
    await DB.insertQuranRecord(QuranRecord(
      studentId: s.id!, trackId: widget.trackId, date: date,
      fromPage: from, toPage: to, createdAt: DateTime.now().toIso8601String(),
    ));
    await _reload();
  }
}
