import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/storage_service.dart';
import '../services/alarm_scheduler.dart';
import '../services/notification_service.dart';
import 'edit_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
    NotificationService.requestPermissions();
  }

  Future<void> _loadReminders() async {
    final data = await _storage.load();
    setState(() {
      _reminders = data;
    });
  }

  Future<void> _toggleReminder(Reminder r, bool enabled) async {
    final updated = r.copyWith(enabled: enabled);
    final index = _reminders.indexWhere((element) => element.id == r.id);
    if (index != -1) {
      _reminders[index] = updated;
      await _storage.save(_reminders);
      setState(() {});

      if (enabled) {
        await AlarmScheduler.schedule(updated);
      } else {
        await AlarmScheduler.cancel(updated.id);
      }
    }
  }

  Future<void> _deleteReminder(Reminder r) async {
    await AlarmScheduler.cancel(r.id);
    _reminders.removeWhere((element) => element.id == r.id);
    await _storage.save(_reminders);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنبهات المتكررة'),
        centerTitle: true,
      ),
      body: _reminders.isEmpty
          ? const Center(child: Text('لا توجد منبهات، أضف واحداً الآن.'))
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];
                return Dismissible(
                  key: Key(r.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteReminder(r),
                  child: ListTile(
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('كل ${r.intervalMinutes} دقيقة'),
                    trailing: Switch(
                      value: r.enabled,
                      onChanged: (val) => _toggleReminder(r, val),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditReminderScreen(reminder: r),
                        ),
                      );
                      _loadReminders();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditReminderScreen()),
          );
          _loadReminders();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
