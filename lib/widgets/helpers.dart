import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// أدوات مساعدة: التواريخ وأسماء الأيام بالعربية
class DateUtilsX {
  static final _ar = Locale('ar');

  static String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String dayName(DateTime d) => DateFormat('EEEE', 'ar').format(d);

  static Future<String?> pickDate(BuildContext context, {String? initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial != null ? DateTime.tryParse(initial) ?? now : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: _ar,
    ).then((d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d));
  }

  static String formatArabic(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return '${dayName(d)} ${DateFormat('yyyy-MM-dd').format(d)}';
  }
}

Future<bool> confirmDialog(BuildContext context, String text) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
      ],
    ),
  );
  return r == true;
}

void snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
