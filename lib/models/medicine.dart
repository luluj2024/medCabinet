import 'package:flutter_test/flutter_test.dart';

class Medicine {
  final int? id;
  final String name;
  final DateTime expiryDate;
  final int quantity;
  final String location;
  final String? notes;
  final DateTime? createdAt;
//   perhaps add picture later

  Medicine({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.quantity,
    required this.location,
    this.notes,
    this.createdAt,
  });

  Medicine copyWith({
    int? id,
    String? name,
    DateTime? expiryDate,
    int? quantity,
    String? location,
    String? notes,
    DateTime? createdAt,
  }){
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(), // toIso8601String() converts DateTime to string
      'quantity': quantity,
      'location': location,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static Medicine fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String,
      expiryDate: DateTime.parse(map['expiryDate']), // DateTime.parse() converts string to DateTime
      quantity: map['quantity'] as int,
      location: map['location'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

}