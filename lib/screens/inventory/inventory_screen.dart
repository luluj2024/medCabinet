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
    _loadMedicines();
  }

  void _loadMedicines() {
    setState(() {
      _medicines = MedicineDao.instance.getAllByName();
    });
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    await MedicineDao.instance.deleteById(medicine.id!);
    _loadMedicines(); // Refresh the list after deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${medicine.name}" deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Medicine>>(
        future: _medicines,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final meds = snapshot.data ?? [];

          if (meds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your medicine cabinet is empty.',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a new medicine.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            itemCount: meds.length,
            itemBuilder: (context, i) {
              final med = meds[i];

              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Dismissible(
                  key: ValueKey(med.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Medicine?'),
                            content: Text(
                              'Are you sure you want to delete "${med.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => _deleteMedicine(med),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    title: Text(
                      med.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 8.0),
                            Text(
                                'Expires: ${DateFormat('yyyy-MM-dd').format(med.expiryDate)}'),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 8.0),
                            Text(med.location),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('x${med.quantity}',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    onTap: () async {
                      final refreshed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => MedicineDetailScreen(medicine: med),
                        ),
                      );
                      if (refreshed == true) {
                        _loadMedicines();
                      }
                    },
                  ),
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
          if (added == true) {
            _loadMedicines();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
