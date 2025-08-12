import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../models/patient.dart';

class DbService {
  late Connection _conn;

  Future<void> open() async {
    _conn = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'password',
      ),
      // The postgres server hosted locally doesn't have SSL by default. If you're
      // accessing a postgres server over the Internet, the server should support
      // SSL and you should swap out the mode with `SslMode.verifyFull`.
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('has connection!');
  }

  Future<void> close() async {
    if (_conn.isOpen) {
      await _conn.close();
    }
  }

  /// Loads one row per patient using the `patient_full` view.
  Future<List<Patient>> loadPatients() async {
    final conn = _conn;
    if (conn == null) {
      throw StateError('Connection is not open.');
    }

    final rows = await conn.execute('SELECT * FROM patient_full;');

    final List<Patient> patients = [];

    for (final row in rows) {
      final id = row[0] as String;
      final name = row[1] as String;
      final insuranceProvider = row[2] as String;

      final List<String> notes =
          (row[3] as List).map((e) => e.toString()).toList();

      final dynamic kmRaw = row[4];
      final List<dynamic> kmList = kmRaw is String
          ? (jsonDecode(kmRaw) as List<dynamic>)
          : (kmRaw as List<dynamic>? ?? const []);

      final keywordPoints = kmList
          .map((e) => KeywordPoint.fromMap(e as Map<String, dynamic>))
          .toList();

      patients.add(
        Patient(
          id: id,
          name: name,
          insuranceProvider: insuranceProvider,
          pastNotes: notes,
          keywordMap: keywordPoints,
        ),
      );
    }
    return patients;
  }
}
