import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/medicine.dart';
import '../../services/db/medicine_dao.dart';

class ExpiryScreen extends StatefulWidget{
  const ExpiryScreen({super.key});

  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> {
  late Future<List<Medicine>> _medicines;

  @override
  void initState() {
    super.initState();
    _medicines = MedicineDao.instance.getAllByExpiryDate();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int _daysLeft(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDate.difference(today).inDays;
  }

  IconData _statusIcon(int days){
    if(days < 0) return Icons.error;
    if(days <= 7) return Icons.warning;
    if(days <= 30) return Icons.hourglass_bottom;
    return Icons.check_circle;
  }

  Color _statusColor(int days){
    if(days < 0) return Colors.red;
    if(days <= 7) return Colors.orange;
    if(days <= 30) return Colors.amber;
    return Colors.green;
  }

  void _refresh() {
    setState(() {
      _medicines = MedicineDao.instance.getAllByExpiryDate();
    });
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    await MedicineDao.instance.deleteById(medicine.id!);
    _refresh();
  }


  Widget _buildSection(String title, Color color, List<Medicine> meds) {
    if(meds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),

        ...meds.map(
          (med) {
            final daysLeft = _daysLeft(med.expiryDate);
            final color = _statusColor(daysLeft);

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
                leading: Icon(
                  _statusIcon(daysLeft),
                  color: color,
                ),
                title: Text(
                  med.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                subtitle: Text(
                  'Expiry: ${_formatDate(med.expiryDate)} • ${med.location}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      daysLeft < 0 ? 'Expired' : '$daysLeft d',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'left',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
      }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
        future: _medicines,
        builder: (context, snapshot){
          if(snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final meds = snapshot.data ?? [];

          final expired = <Medicine>[];
          final within7 = <Medicine>[];
          final within30 = <Medicine>[];
          final safe = <Medicine>[];

          for(final med in meds) {
            final daysLeft = _daysLeft(med.expiryDate);

            if(daysLeft <= 0) {
              expired.add(med);
            } else if(daysLeft <= 7) {
              within7.add(med);
            } else if (daysLeft <= 30) {
              within30.add(med);
            } else {
              safe.add(med);
            }
          }

          if(meds.isEmpty){
            return const Center(child: Text('No medicines found.'));
          }

          return ListView(
            children: [
              _buildSection('Expired', Colors.red, expired),
              _buildSection('Expiring within 30 days', Colors.orange, within30),
              _buildSection('Expiring Within 7 days', Colors.amber, within7),
              _buildSection('Safe', Colors.green, safe)
            ],
          );
        },
    );
  }
}