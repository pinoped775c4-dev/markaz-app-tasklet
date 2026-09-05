import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../state/app_state.dart';
import 'track_screen.dart';
import '../widgets/design.dart';

/// الصفحة الرئيسية للمعلم: 4 مسارات
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WColors.wa,
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحباً ${state.teacher!.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const Text('مساراتك الأربعة — اختر مساراً للدخول',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95),
        itemCount: Tracks.ids.length,
        itemBuilder: (context, i) {
          final id = Tracks.ids[i];
          return Card(
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TrackScreen(trackId: id))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.asset(Tracks.image(id), fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(Tracks.name(id),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
