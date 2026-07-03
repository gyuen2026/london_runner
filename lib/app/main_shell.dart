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
      body: const SetupScreen(),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppTheme.surfaceElevated,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileScreen(voice: _voice)),
          );
        },
        child: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
      ),
    );
  }
}
