import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/storage_service.dart';
import '../services/alarm_scheduler.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const EditReminderScreen({Key? key, this.reminder}) : super(key: key);

  @override
  _EditReminderScreenState createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _nameController = TextEditingController();
  int _interval = 30;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _nameController.text = widget.reminder!.name;
      _interval = widget.reminder!.intervalMinutes;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    final storage = StorageService();
    final all = await storage.load();

    Reminder newReminder;
    if (widget.reminder == null) {
      final newId = await storage.nextId();
      newReminder = Reminder(
        id: newId,
        name: _nameController.text.trim(),
        intervalMinutes: _interval,
        enabled: true,
      );
      all.add(newReminder);
    } else {
      newReminder = widget.reminder!.copyWith(
        name: _nameController.text.trim(),
        intervalMinutes: _interval,
      );
      final index = all.indexWhere((e) => e.id == newReminder.id);
      if (index != -1) all[index] = newReminder;
    }

    await storage.save(all);

    if (newReminder.enabled) {
      await AlarmScheduler.schedule(newReminder);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'إضافة تنبيه' : 'تعديل التنبيه'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم التنبيه (مثال: اشرب ماء)'),
            ),
            const SizedBox(height: 20),
            Text('التكرار: كل $_interval دقيقة'),
            Slider(
              value: _interval.toDouble(),
              min: 1,
              max: 120,
              divisions: 119,
              label: _interval.toString(),
              onChanged: (val) {
                setState(() {
                  _interval = val.toInt();
                });
              },
            ),
            Wrap(
              spacing: 10,
              children: [15, 30, 45, 60].map((mins) {
                return ChoiceChip(
                  label: Text('$mins دقيقة'),
                  selected: _interval == mins,
                  onSelected: (selected) {
                    if (selected) setState(() => _interval = mins);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('حفظ التنبيه'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
