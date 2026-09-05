import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'lessons_tab.dart';
import 'mutun_tab.dart';
import 'quran_tab.dart';

/// شاشة المسار: ثلاثة أقسام (الدروس / المتون / القرآن)
class TrackScreen extends StatelessWidget {
  final String trackId;
  const TrackScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Tracks.name(trackId)),
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(Tracks.image(trackId), fit: BoxFit.cover),
            ),
          ),
          bottom: const TabBar(tabs: [
            Tab(text: 'الدروس'),
            Tab(text: 'المتون'),
            Tab(text: 'القرآن'),
          ]),
        ),
        body: TabBarView(children: [
          LessonsTab(trackId: trackId),
          MutunTab(trackId: trackId),
          QuranTab(trackId: trackId),
        ]),
      ),
    );
  }
}
