import 'package:flutter/material.dart';

import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LondonRunnerApp());
}

class LondonRunnerApp extends StatelessWidget {
  const LondonRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'London Runner',
      theme: AppTheme.dark(),
      home: const SetupScreen(),
    );
  }
}
