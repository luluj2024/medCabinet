import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/medicine.dart';
import '../../services/db/medicine_dao.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Medicine>> _medicines;

  @override
  void initState() {
    super.initState();
    _medicines = MedicineDao.instance.getAll();
  }

  void _refresh() {
    setState(() {
      _medicines = MedicineDao.instance.getAll();
    });
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    await MedicineDao.instance.deleteById(medicine.id!);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');

    return Scaffold(
      body: FutureBuilder<List<Medicine>>(
        future: _medicines,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final meds = snapshot.data ?? [];

          if (meds.isEmpty) {
            return const Center(
              child: Text('No medicines found. Tap + to add one.'),
            );
          }

          return ListView.separated(
            itemCount: meds.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final med = meds[i];
              return Dismissible(
                key: ValueKey(med.id ?? '${med.name}-${med.createdAt}'),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,

                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Medicine?'),
                          content: Text(
                            'Are you sure you want to delete ${med.name}?',
                          ),
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
                },

                onDismissed: (_) => _deleteMedicine(med),
                child: ListTile(
                  title: Text(med.name),
                  subtitle: Text(
                    'Expiry: ${fmt.format(med.expiryDate)} * ${med.location}',
                  ),
                  trailing: Text('x${med.quantity}'),
                  onTap: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => MedicineDetailScreen(medicine: med),
                      ),
                    );
                    if (updated == true) _refresh();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );
          if (added == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
