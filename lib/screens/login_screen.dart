import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/database.dart';
import '../core/constants.dart';
import '../state/app_state.dart';

/// شاشة الدخول: أول تشغيل = إنشاء حساب الإدارة، بعدها دخول إدارة أو معلم
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtl = TextEditingController();
  final passCtl = TextEditingController();
  bool firstRun = true;
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final adminUser = await DB.getSetting(AppKeys.adminUser);
    setState(() { firstRun = adminUser == null; busy = false; });
  }

  Future<void> _submit() async {
    final u = userCtl.text.trim(), p = passCtl.text.trim();
    if (u.isEmpty || p.isEmpty) { setState(() => error = 'أدخل اسم المستخدم وكلمة المرور'); return; }
    final state = context.read<AppState>();
    if (firstRun) {
      await DB.setSetting(AppKeys.adminUser, u);
      await DB.setSetting(AppKeys.adminPass, p);
      await DB.setSetting(AppKeys.adminName, 'الإدارة');
      state.loginAsAdmin();
      return;
    }
    final adminUser = await DB.getSetting(AppKeys.adminUser);
    final adminPass = await DB.getSetting(AppKeys.adminPass);
    if (u == adminUser && p == adminPass) {
      state.loginAsAdmin();
      return;
    }
    final t = await DB.teacherLogin(u, p);
    if (t != null) { state.loginAsTeacher(t); return; }
    setState(() => error = 'بيانات الدخول غير صحيحة');
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/logo.webp',
                        width: 110, height: 110, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(firstRun ? 'إعداد حساب الإدارة' : 'مركز السنة للعلوم الشرعية وتأهيل الدعاة',
                      style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  if (firstRun)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('أنشئ حساب المدير (مستخدم واحد)، وسيُستخدم لاحقاً للدخول كإدارة',
                          textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: userCtl,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(firstRun ? 'إنشاء الحساب والدخول' : 'دخول'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
