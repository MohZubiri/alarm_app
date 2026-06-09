import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/alarm_scheduler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService.init();
  await AndroidAlarmManager.initialize();

  // Re-schedule all enabled reminders on start (safety measure)
  final storage = StorageService();
  final reminders = await storage.load();
  for (final r in reminders.where((r) => r.enabled)) {
    await AlarmScheduler.schedule(r);
  }

  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المنبه المتكرر',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Tajawal', // Assuming an Arabic font later if needed
      ),
      home: const HomeScreen(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
