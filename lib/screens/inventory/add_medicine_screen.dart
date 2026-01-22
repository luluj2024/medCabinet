import 'package:flutter/material.dart';

import '../../models/medicine.dart';
import '../../services/api/openfda_service.dart';
import '../../services/db/medicine_dao.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    // final initial = _expiryDate ?? now.add(const Duration(days: 30));
    final initial = _expiryDate ?? now;


    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _searchOpenFda() async {
    final query = _nameController.text.trim();
    if(query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name first')),
      );
      return;
    }

    try {
      final results = await OpenfdaService.instance.searchDrugLabel(query, limit: 5);

      if(!mounted) return;

      if(results.isEmpty) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No results found'),
            content: Text('No openFDA label found for "$query"'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('openFDA Results'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = results[i];
                  final title = r.brandName ?? r.genericName ?? '(unknown)';
                  final subtitle = r.purpose ?? r.warnings ?? '';
                  return ListTile(
                    title: Text(title),
                    subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      final buffer = StringBuffer();
                      if(r.purpose != null) {
                        buffer.writeln('Purpose: ${r.purpose}\n');
                        buffer.writeln();
                      }

                      if(r.warnings != null) {
                        buffer.writeln('Warnings:');
                        buffer.writeln(r.warnings);
                      }

                      setState(() {
                        _notesController.text = buffer.toString().trim();
                      });

                      Navigator.of(context).pop();

                      },
                  );
                },
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
        ),
      );
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OpenFDAError: $e')),
      );
    }
  }

  Future<void> _saveMedicine() async {
      if(!_formKey.currentState!.validate()) return;

      if(_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date')),
        );
        return;
      }

      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;

      final med = Medicine(
        name: _nameController.text.trim(),
        expiryDate: _expiryDate!,
        quantity: quantity,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await MedicineDao.instance.insert(med);

      if(!mounted) return;
      Navigator.of(context).pop(true);
    }

  @override
  Widget build(BuildContext context) {
    final expiryText = _expiryDate == null ? 'Select expiry date' : _formatDate(_expiryDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
                validator: (value){
                  final n = int.tryParse((value ?? '').trim());
                  if(n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location(e.g., Kitchen)',
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _pickExpiryDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(expiryText),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _searchOpenFda,
                icon: const Icon(Icons.search),
                label: const Text('Search openFDA(optional)'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes(optional)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              FilledButton(onPressed: _saveMedicine, child: const Text('Save')),

            ],
          ),
        ),
      ),
    );
  }
}


