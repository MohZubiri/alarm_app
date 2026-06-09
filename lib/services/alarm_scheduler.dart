import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/reminder.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AlarmScheduler {
  static Future<void> schedule(Reminder reminder) async {
    await AndroidAlarmManager.periodic(
      Duration(minutes: reminder.intervalMinutes),
      reminder.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  static Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}

@pragma('vm:entry-point')
void alarmCallback(int id) async {
  // Initialize services inside isolate
  await NotificationService.initInBackground();
  
  // Get reminder name
  final name = await StorageService.nameFor(id);
  
  // Show notification
  await NotificationService.showAlarmNotification(id, name ?? 'تنبيه');
}
