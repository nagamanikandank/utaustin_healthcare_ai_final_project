import 'dart:math';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../../util/date_utils.dart';
import '../db/db_service.dart';

class MockData {
  static final DbService _db = DbService();

  static Future<List<Patient>> loadPatientsFromDb() async {
    await _db.open();
    final patients1 = await _db.loadPatients();
    await _db.close();
    return patients1;
  }

  /*[
    Patient(
      id: 'p1',
      name: 'Alice Johnson',
      insuranceProvider: 'Blue Cross Blue Shield',
      pastNotes: [
        '2025-07-10: Follow-up on hypertension. Adjusted medication.',
        '2025-06-02: Routine checkup. Recommended increased exercise.',
        '2025-05-14: Mild dizziness reported. Ordered labs.'
      ],
      keywordMap: [
        KeywordPoint(label: 'hypertension', x: -0.8, y: 0.6),
        KeywordPoint(label: 'dizziness', x: -0.2, y: 0.1),
        KeywordPoint(label: 'labs', x: 0.1, y: -0.4),
        KeywordPoint(label: 'exercise', x: 0.7, y: 0.2),
        KeywordPoint(label: 'medication', x: -0.5, y: -0.7),
      ],
    ),
    Patient(
      id: 'p2',
      name: 'Brian Patel',
      insuranceProvider: 'Aetna',
      pastNotes: [
        '2025-07-29: Asthma check. Inhaler technique reviewed.',
        '2025-05-21: Seasonal allergies. Antihistamine prescribed.',
      ],
      keywordMap: [
        KeywordPoint(label: 'asthma', x: -0.7, y: -0.2),
        KeywordPoint(label: 'inhaler', x: -0.3, y: 0.8),
        KeywordPoint(label: 'allergies', x: 0.2, y: 0.5),
        KeywordPoint(label: 'antihistamine', x: 0.8, y: -0.3),
      ],
    ),
    Patient(
      id: 'p3',
      name: 'Chloe Kim',
      insuranceProvider: 'UnitedHealthcare',
      pastNotes: [
        '2025-07-18: Prediabetes counseling. Diet & exercise plan.',
        '2025-04-09: Lipid panel elevated. Statin discussed.',
      ],
      keywordMap: [
        KeywordPoint(label: 'prediabetes', x: -0.6, y: 0.4),
        KeywordPoint(label: 'diet', x: -0.1, y: -0.8),
        KeywordPoint(label: 'exercise', x: 0.4, y: -0.6),
        KeywordPoint(label: 'lipids', x: 0.6, y: 0.7),
        KeywordPoint(label: 'statin', x: 0.9, y: -0.1),
      ],
    ),
    Patient(
      id: 'p4',
      name: 'Diego Sanchez',
      insuranceProvider: 'Cigna',
      pastNotes: [
        '2025-06-30: Knee pain. Physical therapy referral.',
        '2025-03-19: Imaging (MRI) reviewed. No tear.',
      ],
      keywordMap: [
        KeywordPoint(label: 'knee pain', x: -0.9, y: -0.1),
        KeywordPoint(label: 'PT', x: -0.4, y: 0.3),
        KeywordPoint(label: 'MRI', x: 0.3, y: 0.9),
        KeywordPoint(label: 'referral', x: 0.5, y: -0.4),
      ],
    ),
    Patient(
      id: 'p5',
      name: 'Elaine Wong',
      insuranceProvider: 'Humana',
      pastNotes: [
        '2025-07-05: Migraine management. Triptan effective.',
        '2025-02-11: Sleep hygiene discussed.',
      ],
      keywordMap: [
        KeywordPoint(label: 'migraine', x: -0.2, y: 0.9),
        KeywordPoint(label: 'triptan', x: 0.1, y: 0.2),
        KeywordPoint(label: 'sleep', x: 0.7, y: -0.5),
        KeywordPoint(label: 'hygiene', x: -0.6, y: -0.6),
      ],
    ),
  ];*/

  static Future<List<Appointment>> generateWeekAppointments(
      DateTime anyDateInWeek) async {
    final List<Patient> patients = await MockData.loadPatientsFromDb();
    final monday = startOfWeek(anyDateInWeek);
    final rng = Random(42);
    final List<Appointment> appts = [];

    final List<Duration> suggestedStarts = [
      const Duration(hours: 8, minutes: 0),
      const Duration(hours: 9, minutes: 0),
      const Duration(hours: 9, minutes: 30),
      const Duration(hours: 10, minutes: 30),
      const Duration(hours: 11, minutes: 0),
      const Duration(hours: 13, minutes: 0),
      const Duration(hours: 13, minutes: 30),
      const Duration(hours: 14, minutes: 30),
      const Duration(hours: 15, minutes: 30),
      const Duration(hours: 16, minutes: 30),
    ];

    for (int d = 0; d < 5; d++) {
      // Mon-Fri
      final day = monday.add(Duration(days: d));
      // pick 6–8 random slots for the day
      final slots = List.of(suggestedStarts)..shuffle(rng);
      final count = 6 + rng.nextInt(3);
      for (int i = 0; i < count; i++) {
        final start = DateTime(day.year, day.month, day.day).add(slots[i]);
        final end = start.add(const Duration(minutes: 30));
        final patient = patients[(d * 3 + i) % patients.length];
        appts.add(Appointment(
          id: 'a_${day.millisecondsSinceEpoch}_$i',
          patient: patient,
          start: start,
          end: end,
          reason: [
            'Follow-up',
            'New patient',
            'Medication review',
            'Lab review'
          ][rng.nextInt(4)],
        ));
      }
    }
    return appts;
  }
}
