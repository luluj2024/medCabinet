import 'package:flutter/material.dart';
import 'package:med_cabinet/services/notifications/notification_service.dart';
import 'screens/tabs/main_tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  // Request exact alarm permission (for Android 12+)
  await NotificationService.instance.requestExactAlarmPermission();

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
