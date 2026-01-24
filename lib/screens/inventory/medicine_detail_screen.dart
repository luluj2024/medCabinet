import 'package:flutter/material.dart';
import 'package:med_cabinet/models/medicine.dart';

import '../../services/db/medicine_dao.dart';
import '../../services/notifications/notification_service.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});
  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Medicine _med;
  bool _changed = false;
  bool _savingReminder = false;


  @override
  void initState() {
    super.initState();
    _med = widget.medicine;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  TimeOfDay _currentReminderTime() {
    final h = _med.dailyReminderHour ?? 9;
    final m = _med.dailyReminderMinute ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _saveMedicine(Medicine updated) async {
    await MedicineDao.instance.update(updated);
    setState(() {
      _med = updated;
      _changed = true;
    });

    if (mounted) {}
  }


  Future<void> _setDailyReminderEnabled(bool enabled) async {
    if (_savingReminder) return;

    if (_med.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save this medicine first.')),
      );
      return;
    }

    setState(() => _savingReminder = true);

    final medId = _med.id!;
    final notifId = NotificationService.instance.dailyReminderNotificationId(medId);

    try {
      if (enabled) {
        setState(() {
          _med = _med.copyWith(dailyReminderEnabled: true);
        });

        final picked = await showTimePicker(
          context: context,
          initialTime: _currentReminderTime(),
        );

        if (picked == null) {
          setState(() {
            _med = _med.copyWith(dailyReminderEnabled: false);
          });
          return;
        }

        debugPrint('>>> scheduling test');

        await NotificationService.instance.scheduleDailyReminder(
          id: notifId,
          title: _med.name,
          body: 'Time to take your medicine!',
          hour: picked.hour,
          minute: picked.minute,
        );

        debugPrint('>>> scheduling test done');

        // for testing -------------------
        debugPrint('>>> scheduling test in 120s');

        await NotificationService.instance.scheduleAfterSeconds(
          id: 9999,
          title: 'Test in 10s',
          body: 'If you see this, scheduling works',
          seconds: 120,
        );

        debugPrint('<<< scheduled test done');

        debugPrint('>>> scheduling test now');

        await NotificationService.instance.showNow(id: 123, title: 'test', body: 'testing');

        debugPrint('>>> scheduling test done');

        final updated = _med.copyWith(
          dailyReminderEnabled: true,
          dailyReminderHour: picked.hour,
          dailyReminderMinute: picked.minute,
        );
        await _saveMedicine(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daily reminder set: ${picked.format(context)}')),
        );
      } else {
        setState(() {
          _med = _med.copyWith(dailyReminderEnabled: false);
        });

        await NotificationService.instance.cancel(notifId);

        final updated = _med.copyWith(dailyReminderEnabled: false);
        await _saveMedicine(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily reminder disabled')),
        );
      }
    } catch (e) {
      setState(() {
        _med = _med.copyWith(dailyReminderEnabled: !enabled);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }


  Future<void> _changeDailyReminderTime() async {
    if (_med.id == null || !_med.dailyReminderEnabled) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _currentReminderTime(),
    );

    if (picked == null) return;

    final medId = _med.id!;
    final notifId = NotificationService.instance.dailyReminderNotificationId(
      medId,
    );

    await NotificationService.instance.scheduleDailyReminder(
      id: notifId,
      title: _med.name,
      body: 'Time to take your medicine 💊',
      hour: picked.hour,
      minute: picked.minute,
    );

    final updated = _med.copyWith(
      dailyReminderHour: picked.hour,
      dailyReminderMinute: picked.minute,
    );
    await _saveMedicine(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder time updated: ${picked.format(context)}'),
      ),
    );
  }

  Future<void> _deleteMedicine(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: Text('Are you sure you want to delete ${_med.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),

              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    if (_med.id != null && _med.dailyReminderEnabled) {
      final notifId = NotificationService.instance.dailyReminderNotificationId(
        _med.id!,
      );
      await NotificationService.instance.cancel(notifId);
    }

    if (_med.id != null) {
      await MedicineDao.instance.deleteById(_med.id!);
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final notes = (_med.notes ?? '').trim();
    final reminderTimeText = _currentReminderTime().format(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Medicine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddMedicineScreen(medicine: _med),
                ),
              );
              if (changed == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),

          IconButton(
            onPressed: () => _deleteMedicine(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _med.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expiry: ${_formatDate(_med.expiryDate)}'),
                  const SizedBox(height: 6),
                  Text('Quantity: ${_med.quantity}'),
                  const SizedBox(height: 6),
                  Text('Location: ${_med.location}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Reminder'),
                  subtitle: Text(
                    _med.dailyReminderEnabled ? 'Enabled: $reminderTimeText' : 'Off',
                  ),
                  value: _med.dailyReminderEnabled,
                  onChanged: _savingReminder ? null : (v) => _setDailyReminderEnabled(v),
                ),
                if (_med.dailyReminderEnabled)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder Time'),
                    subtitle: Text(reminderTimeText),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changeDailyReminderTime,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Notes / Drug Info',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: notes.isEmpty
                ? const Text('No notes', style: TextStyle(color: Colors.grey))
                : SelectableText(notes),
          ),
        ],
      ),
    ),);
  }
}