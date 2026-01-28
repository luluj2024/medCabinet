import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/medicine.dart';
import '../../services/db/medicine_dao.dart';
import '../inventory/medicine_detail_screen.dart';

class ExpiryScreen extends StatefulWidget {
  const ExpiryScreen({super.key});

  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> {
  late Future<List<Medicine>> _medicines;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  void _loadMedicines() {
    setState(() {
      _medicines = MedicineDao.instance.getAllByExpiryDate();
    });
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    await MedicineDao.instance.deleteById(medicine.id!);
    _loadMedicines(); // Refresh list
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${medicine.name}" deleted.')),
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog(Medicine med) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to delete "${med.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }


  int _daysLeft(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDate.difference(today).inDays;
  }

  IconData _statusIcon(int days) {
    if (days < 0) return Icons.error;
    if (days <= 7) return Icons.warning;
    if (days <= 30) return Icons.hourglass_bottom;
    return Icons.check_circle;
  }

  Color _statusColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.orange;
    if (days <= 30) return Colors.amber;
    return Colors.green;
  }

  Widget _buildSection(String title, Color color, List<Medicine> meds) {
    if (meds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...meds.map((med) {
          final daysLeft = _daysLeft(med.expiryDate);
          final color = _statusColor(daysLeft);

          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Dismissible(
              key: ValueKey(med.id ?? med.createdAt),
              background: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _showDeleteConfirmationDialog(med),
              onDismissed: (_) => _deleteMedicine(med),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
                leading: Icon(
                  _statusIcon(daysLeft),
                  color: color,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        med.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8.0),
                        Text('Expiry: ${DateFormat.yMMMd().format(med.expiryDate)}'),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8.0),
                        Text(med.location),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8.0),
                        Text('Quantity: ${med.quantity}'),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      daysLeft < 0 ? 'Expired' : '$daysLeft d',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () async {
                          final confirmed = await _showDeleteConfirmationDialog(med);
                          if (confirmed) {
                            _deleteMedicine(med);
                          }
                        },
                      ),
                    )
                  ],
                ),
                // onTap: () async {
                //   final refreshed = await Navigator.of(context).push<bool>(
                //     MaterialPageRoute(
                //       builder: (_) => MedicineDetailScreen(medicine: med),
                //     ),
                //   );
                //   if (refreshed == true) {
                //     _loadMedicines();
                //   }
                // },
              ),
            ),
          );
        }).toList(),
      ],
    );
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
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No medicines to track.',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Medicines you add will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final expired = <Medicine>[];
          final within7 = <Medicine>[];
          final within30 = <Medicine>[];
          final safe = <Medicine>[];

          for (final med in meds) {
            final daysLeft = _daysLeft(med.expiryDate);

            if (daysLeft < 0) {
              expired.add(med);
            } else if (daysLeft <= 7) {
              within7.add(med);
            } else if (daysLeft <= 30) {
              within30.add(med);
            } else {
              safe.add(med);
            }
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 80), // For FAB
            children: [
              _buildSection('Expired', Colors.red, expired),
              _buildSection('Expiring Within 7 days', Colors.orange, within7),
              _buildSection('Expiring within 30 days', Colors.amber, within30),
              _buildSection('Safe', Colors.green, safe)
            ],
          );
        },
      ),
    );
  }
}
