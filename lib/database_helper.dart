import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'models/tenant.dart';
import 'models/room.dart';
import 'models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Updated version for schema changes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        mobile TEXT NOT NULL,
        sex TEXT NOT NULL,
        roomId INTEGER,
        monthsPaid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rent REAL NOT NULL,
        maxOccupants INTEGER NOT NULL,
        occupants TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenantId INTEGER,
        amountGiven REAL NOT NULL,
        monthsCovered INTEGER NOT NULL,
        remainingBalance REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tenants ADD COLUMN roomId INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenantId INTEGER,
          amountGiven REAL NOT NULL,
          monthsCovered INTEGER NOT NULL,
          remainingBalance REAL NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tenants ADD COLUMN monthsPaid INTEGER NOT NULL DEFAULT 0');
    }
  }

  // Tenant CRUD Operations
  Future<int> addTenant(Tenant tenant) async {
    final db = await instance.database;
    return await db.insert('tenants', tenant.toMap());
  }

  Future<List<Tenant>> getAllTenants() async {
    final db = await instance.database;
    final result = await db.query('tenants');
    return result.map((json) => Tenant.fromMap(json)).toList();
  }

  Future<Tenant?> getTenant(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Tenant.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> updateTenant(Tenant tenant) async {
    final db = await instance.database;
    return await db.update(
      'tenants',
      tenant.toMap(),
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  Future<int> deleteTenant(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Room CRUD Operations
  Future<int> addRoom(Room room) async {
    final db = await instance.database;
    return await db.insert('rooms', room.toMap());
  }

  Future<List<Room>> getAllRooms() async {
    final db = await instance.database;
    final result = await db.query('rooms');
    return result.map((json) => Room.fromMap(json)).toList();
  }

  Future<Room?> getRoom(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Room.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> updateRoom(Room room) async {
    final db = await instance.database;
    return await db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<int> deleteRoom(int id) async {
    final db = await instance.database;

    // Set roomId to null for all tenants assigned to this room
    await db.update(
      'tenants',
      {'roomId': null},
      where: 'roomId = ?',
      whereArgs: [id],
    );

    // Now, delete the room itself
    return await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Tenant>> getTenantsWithoutRooms() async {
    final db = await instance.database;
    final result = await db.query(
      'tenants',
      where: 'roomId IS NULL',
    );
    return result.map((json) => Tenant.fromMap(json)).toList();
  }

  // Transaction CRUD Operations
  Future<int> addTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future<List<Transaction>> getRecentTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: 10,
    );

    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
