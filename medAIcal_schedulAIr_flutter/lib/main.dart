import 'package:flutter/material.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/analysis/analysis_page.dart';

void main() {
  runApp(const SchedulAIrApp());
}

class SchedulAIrApp extends StatelessWidget {
  const SchedulAIrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'medAIcal schedulAIr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 22, 197, 75),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/analysis': (_) => const AnalysisPage(),
      },
    );
  }
}
