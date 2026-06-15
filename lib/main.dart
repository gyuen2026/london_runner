import 'package:flutter/material.dart';

import 'screens/setup_screen.dart';

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
      theme: ThemeData.dark(useMaterial3: true),
      home: const SetupScreen(),
    );
  }
}
