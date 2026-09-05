import 'package:flutter/material.dart';

/// ألوان هوية واتساب المعتمدة في التطبيق
class WColors {
  static const wa = Color(0xFF075E54); // الأخضر الداكن
  static const wa2 = Color(0xFF128C7E); // الأخضر المتوسط
  static const lightGreen = Color(0xFF25D366); // أخضر الإنجاز
  static const lightGreenBg = Color(0xFFDCF8C6); // خلفية الفقاعات
  static const bg = Color(0xFFF0F2F5); // خلفية الصفحة
  static const remaining = Color(0xFFE9EDEF); // لون المتبقي في المخطط
  static const txt = Color(0xFF111B21); // لون النص الأساسي
  static const sub = Color(0xFF667781); // لون النص الثانوي
}

/// بطاقة قسم برأس أخضر — مثل رؤوس الأقسام في التصميم المعتمد
class WSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const WSectionCard({super.key, required this.title, required this.children, this.icon = Icons.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x140B141A), blurRadius: 4, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: WColors.wa,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: children)),
      ]),
    );
  }
}

/// بطاقة إحصائية: رقم كبير أخضر وعنوان صغير
class WStatCard extends StatelessWidget {
  final String value;
  final String label;
  const WStatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x140B141A), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: WColors.wa)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: WColors.sub, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// حالة فارغة أنيقة داخل القسم
class WEmpty extends StatelessWidget {
  final String text;
  const WEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDEF)),
      ),
      child: Column(children: [
        const Icon(Icons.event_busy, color: Color(0xFFB0BEC5), size: 30),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center,
            style: const TextStyle(color: WColors.sub, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// شارة صغيرة (نظم / نثر / اسم مسار)
class WChip extends StatelessWidget {
  final String text;
  final Color color;
  const WChip(this.text, {super.key, this.color = WColors.wa2});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
