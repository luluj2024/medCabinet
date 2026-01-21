import 'package:flutter/material.dart';
import 'screens/tabs/main_tabs.dart';

void main() {
  runApp(const MedCabinetApp());
}

class MedCabinetApp extends StatelessWidget {
  const MedCabinetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Cabinet',
      debugShowCheckedModeBanner: false,
      home: const MainTabs(),
    );
  }
}
