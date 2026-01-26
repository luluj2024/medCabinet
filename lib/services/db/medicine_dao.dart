import 'package:sqflite/sqflite.dart';

import '../../models/medicine.dart';
import 'database_helper.dart';

class MedicineDao {
  MedicineDao._internal();

  static final MedicineDao instance = MedicineDao._internal();

  static const String tableName = 'medicines';

  Future<int> insert(Medicine medicine) async {
    final db = await DatabaseHelper().database;
    return await db.insert(
        tableName,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Medicine>> getAllByExpiryDate({String orderBy = 'expiryDate ASC'}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
        tableName,
        orderBy: orderBy,
    );

    return rows.map((row) => Medicine.fromMap(row)).toList();
  }

  Future<List<Medicine>> getAllByName({String orderBy = 'name ASC'}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      tableName,
      orderBy: orderBy,
    );

    return rows.map((row) => Medicine.fromMap(row)).toList();
  }



  Future<Medicine?> getById(int id) async {
    final db = await DatabaseHelper().database;
    final row = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
    );

    if(row.isEmpty) return null;
    return Medicine.fromMap(row.first);
  }

  Future<int> update(Medicine medicine) async {
    if(medicine.id == null) throw ArgumentError('Medicine id cannot be null');

    final db = await DatabaseHelper().database;
    return await db.update(
        tableName,
        medicine.toMap(),
        where: 'id = ?',
        whereArgs: [medicine.id],
    );
  }

  Future<int> deleteById(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
    );
  }

}