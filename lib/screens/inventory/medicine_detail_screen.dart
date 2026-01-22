import 'package:flutter/material.dart';
import 'package:med_cabinet/models/medicine.dart';

import '../../services/db/medicine_dao.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteMedicine(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: Text('Are you sure you want to delete ${medicine.name}?'),
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

    if (medicine.id != null) {
      await MedicineDao.instance.deleteById(medicine.id!);
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final notes = (medicine.notes ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Details'),
        actions: [
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
            medicine.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expiry: ${_formatDate(medicine.expiryDate)}'),
                  const SizedBox(height: 6),
                  Text('Quantity: ${medicine.quantity}'),
                  const SizedBox(height: 6),
                  Text('Location: ${medicine.location}'),
                ],
              ),
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
    );
  }
}
