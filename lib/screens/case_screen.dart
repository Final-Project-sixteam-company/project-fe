import 'package:clueroom/screens/scene_screen.dart';
import 'package:clueroom/screens/submit_screen.dart';
import 'package:clueroom/screens/suspects_screen.dart';
import 'package:clueroom/screens/timeline_screen.dart';
import 'package:flutter/material.dart';
import '../components/ms_bottom_nav.dart';
import '../theme/app_theme.dart';
import 'evidence_screen.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({super.key});

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  int _navIndex = 0;

  static const _kScreens = <Widget>[
    SceneScreen(),
    EvidenceScreen(),
    SuspectsScreen(),
    TimelineScreen(),
    SubmitScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: MSBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      body: IndexedStack(
        index: _navIndex,
        children: _kScreens,
      ),
    );
  }
}