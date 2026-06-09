import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class AlarmRingScreen extends StatelessWidget {
  final int alarmId;
  final String alarmName;

  const AlarmRingScreen({
    Key? key,
    required this.alarmId,
    required this.alarmName,
  }) : super(key: key);

  void _dismiss(BuildContext context) {
    NotificationService.cancel(alarmId);
    // You may also want to use SystemNavigator.pop() or just exit the app if it was launched just for this.
    Navigator.of(context).pop();
  }

  void _snooze(BuildContext context) {
    // Implement snooze logic (e.g., schedule a oneShot alarm for 5 mins)
    // AndroidAlarmManager.oneShot(...)
    NotificationService.cancel(alarmId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              alarmName,
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => _dismiss(context),
                  child: const Text('إيقاف', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => _snooze(context),
                  child: const Text('غفوة (5د)', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
