/// ثوابت عامة: المسارات وأسماؤها
library;

class Tracks {
  static const List<String> ids = ['mafateeh', 'maaraj1', 'maaraj2', 'maaraj3'];
  static const Map<String, String> names = {
    'mafateeh': 'مفاتيح الطلب',
    'maaraj1': 'معارج التحصيل ①',
    'maaraj2': 'معارج التحصيل ②',
    'maaraj3': 'معارج التحصيل ③',
  };
  static String name(String id) => names[id] ?? id;

  /// صورة الأيقونة الخاصة بكل مسار
  static const Map<String, String> images = {
    'mafateeh': 'assets/images/section1.jpg',
    'maaraj1': 'assets/images/section2.jpg',
    'maaraj2': 'assets/images/section3.jpg',
    'maaraj3': 'assets/images/section4.jpg',
  };
  static String image(String id) => images[id] ?? images['mafateeh']!;
}

class AppKeys {
  static const adminUser = 'admin_username';
  static const adminPass = 'admin_password';
  static const adminName = 'admin_name';
}
