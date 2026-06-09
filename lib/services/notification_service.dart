import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'alarm_channel',
    'تنبيهات المنبّه',
    description: 'تنبيهات متكررة بصوت المنبّه',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification actions (DISMISS, SNOOZE) here if needed,
        // or navigate to ring screen.
      },
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationResponseHandler,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
      await androidPlugin.requestExactAlarmsPermission();
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> requestPermissions() async {
    await Permission.notification.request();
  }

  static Future<void> initInBackground() async {
    // Re-initialize inside isolate
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);
  }

  static Future<void> showAlarmNotification(int id, String title) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      actions: [
        const AndroidNotificationAction(
          'DISMISS',
          'إيقاف',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'SNOOZE',
          'غفوة',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id,
      title,
      'حان وقت التنبيه!',
      details,
    );
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}

@pragma('vm:entry-point')
void backgroundNotificationResponseHandler(NotificationResponse response) {
  // Handle background actions like snooze
}
