import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/patient.dart';
import '../models/patient_document.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('doctor_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI for desktop support
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbFolder = await getApplicationDocumentsDirectory();
      final path = p.join(dbFolder.path, 'DoctorApp', filePath);
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
          onConfigure: _onConfigure,
        ),
      );
    } else {
      // Mobile platforms (Android, iOS)
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onConfigure: _onConfigure,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Patients Table
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        bloodGroup TEXT NOT NULL,
        diagnosis TEXT NOT NULL,
        medicalHistory TEXT,
        prescription TEXT,
        status TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        avatarPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Patient Documents & Images Table
    await db.execute('''
      CREATE TABLE patient_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL,
        fileSize TEXT NOT NULL,
        uploadedAt TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Pre-populate with realistic medical sample records for doctor's daily use
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 2)));

    await db.insert('patients', {
      'name': 'Muhammad Ali',
      'age': 45,
      'gender': 'Male',
      'phone': '+92 300 1234567',
      'email': 'ali.muhammad@email.com',
      'bloodGroup': 'B+',
      'diagnosis': 'Stage 2 Hypertension & Angina Pectoris',
      'medicalHistory': 'Family history of cardiovascular issues. Smoker for 10 years (quit in 2022).',
      'prescription': '1. Tab Amlodipine 5mg (1-0-0)\n2. Tab Losartan 50mg (0-0-1)\n3. Low sodium diet and 30min daily walk.',
      'status': 'Critical',
      'visitDate': today,
      'avatarPath': null,
      'createdAt': now,
    });

    await db.insert('patients', {
      'name': 'Fatima Zahra',
      'age': 32,
      'gender': 'Female',
      'phone': '+92 321 7654321',
      'email': 'fatima.zahra@email.com',
      'bloodGroup': 'O+',
      'diagnosis': 'Type 2 Diabetes Mellitus (Under Control)',
      'medicalHistory': 'Gestational diabetes during second pregnancy. No known drug allergies.',
      'prescription': '1. Tab Metformin 500mg twice daily with meals\n2. Blood glucose fasting monitoring every 3 days\n3. HbA1c test scheduled for next month.',
      'status': 'Active',
      'visitDate': today,
      'avatarPath': null,
      'createdAt': now,
    });

    await db.insert('patients', {
      'name': 'Hamza Ahmed',
      'age': 26,
      'gender': 'Male',
      'phone': '+92 333 4567890',
      'email': 'hamza.ahmed@email.com',
      'bloodGroup': 'A+',
      'diagnosis': 'Acute Bronchitis & Seasonal Allergies',
      'medicalHistory': 'Mild dust allergy. Recurrent chest infections during autumn.',
      'prescription': '1. Cap Azithromycin 500mg once daily for 5 days\n2. Syrup Levocetirizine 5ml at bedtime\n3. Salbutamol inhaler PRN.',
      'status': 'Recovered',
      'visitDate': yesterday,
      'avatarPath': null,
      'createdAt': now,
    });

    await db.insert('patients', {
      'name': 'Ayesha Khan',
      'age': 58,
      'gender': 'Female',
      'phone': '+92 345 9876543',
      'email': 'ayesha.khan@email.com',
      'bloodGroup': 'AB+',
      'diagnosis': 'Osteoarthritis & Vitamin D Deficiency',
      'medicalHistory': 'Knee pain for 3 years. Post-menopausal bone density scan recommended.',
      'prescription': '1. Tab Calcium + Vit D3 daily\n2. Glucosamine chondroitin supplement\n3. Gentle physiotherapy and warm compress.',
      'status': 'Follow-up',
      'visitDate': twoDaysAgo,
      'avatarPath': null,
      'createdAt': now,
    });
  }

  // --- CRUD Operations for Patients ---

  Future<int> insertPatient(Patient patient) async {
    final db = await instance.database;
    return await db.insert('patients', patient.toMap());
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await instance.database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await instance.database;
    // Associated documents are automatically cascade-deleted due to foreign key
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Patient>> getPatients({String? query, String? statusFilter, String? sortBy}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      whereClause += '(name LIKE ? OR phone LIKE ? OR diagnosis LIKE ?)';
      final q = '%${query.trim()}%';
      whereArgs.addAll([q, q, q]);
    }

    if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(statusFilter);
    }

    String orderBy = 'id DESC';
    if (sortBy == 'Name') {
      orderBy = 'name ASC';
    } else if (sortBy == 'Age') {
      orderBy = 'age ASC';
    } else if (sortBy == 'Recent') {
      orderBy = 'id DESC';
    }

    final result = await db.query(
      'patients',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Patient.fromMap(result.first);
    }
    return null;
  }

  // --- Document Operations ---

  Future<int> insertDocument(PatientDocument doc) async {
    final db = await instance.database;
    return await db.insert('patient_documents', doc.toMap());
  }

  Future<List<PatientDocument>> getDocumentsByPatientId(int patientId) async {
    final db = await instance.database;
    final result = await db.query(
      'patient_documents',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'id DESC',
    );
    return result.map((map) => PatientDocument.fromMap(map)).toList();
  }

  Future<int> deleteDocument(int id) async {
    final db = await instance.database;
    return await db.delete(
      'patient_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Dashboard Statistics ---

  Future<Map<String, int>> getStatistics() async {
    final db = await instance.database;
    final all = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
    final active = await db.rawQuery('SELECT COUNT(*) as count FROM patients WHERE status = "Active"');
    final critical = await db.rawQuery('SELECT COUNT(*) as count FROM patients WHERE status = "Critical"');
    final recovered = await db.rawQuery('SELECT COUNT(*) as count FROM patients WHERE status = "Recovered"');
    final followUp = await db.rawQuery('SELECT COUNT(*) as count FROM patients WHERE status = "Follow-up"');

    return {
      'total': Sqflite.firstIntValue(all) ?? 0,
      'active': Sqflite.firstIntValue(active) ?? 0,
      'critical': Sqflite.firstIntValue(critical) ?? 0,
      'recovered': Sqflite.firstIntValue(recovered) ?? 0,
      'followUp': Sqflite.firstIntValue(followUp) ?? 0,
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
