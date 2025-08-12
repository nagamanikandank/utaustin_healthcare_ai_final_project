import 'patient.dart';

class Appointment {
  final String id;
  final Patient patient;
  final DateTime start;
  final DateTime end;
  final String reason;

  Appointment({
    required this.id,
    required this.patient,
    required this.start,
    required this.end,
    required this.reason,
  });
}
