import 'package:flutter/material.dart';

import 'package:london_runner/app/main_shell.dart';
import 'package:london_runner/core/theme/app_theme.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeenGreenApp());
}

class GeenGreenApp extends StatelessWidget {
  const GeenGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEENGREEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}
