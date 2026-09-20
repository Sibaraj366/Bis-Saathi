import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/standards_screen.dart';
import 'screens/compliance_screen.dart';
import 'screens/document_qa_screen.dart';
import 'screens/services_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/responsive_shell.dart';

void main() {
  runApp(const BISSaathiApp());
}

class BISSaathiApp extends StatelessWidget {
  const BISSaathiApp({super.key});

  static const Color bisBlue = Color(0xFF0B5ED7);
  static const Color background = Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIS Saathi',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: bisBlue,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: background,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE2E7F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE2E7F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: bisBlue, width: 1.5),
          ),
        ),
      ),

      // ========================================================
      // MAIN APPLICATION SHELL
      // ========================================================
      home: ResponsiveShell(
        home: const HomeScreen(),
        assistant: const AssistantScreen(),
        standards: const StandardsScreen(),
        compliance: const ComplianceScreen(),
        services: const ServicesScreen(),
        profile: const ProfileScreen(),
      ),

      // ========================================================
      // SECONDARY ROUTES
      // ========================================================
      routes: {
        '/assistant': (context) => const AssistantScreen(),

        '/standards': (context) => const StandardsScreen(),

        '/compliance': (context) => const ComplianceScreen(),

        '/document-qa': (context) => const DocumentQAScreen(),

        '/services': (context) => const ServicesScreen(),

        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
