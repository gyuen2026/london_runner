import 'package:flutter/material.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/services/voice_coach.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/setup_screen.dart';
import 'package:london_runner/features/profile/profile_screen.dart';
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final _voice = VoiceCoach();

  @override
  void initState() {
    super.initState();
    _voice.init();
    UiSound.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          const SetupScreen(),
          ProfileScreen(voice: _voice),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          UiSound.instance.tap();
          setState(() => _tab = i);
        },
        backgroundColor: AppTheme.bg.withValues(alpha: 0.94),
        indicatorColor: AppTheme.surfaceElevated,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run, color: AppTheme.runGreen),
            label: 'Run',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.runGreen),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
