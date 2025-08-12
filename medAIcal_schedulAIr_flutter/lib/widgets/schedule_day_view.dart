import 'package:flutter/material.dart';
import '../core/models/appointment.dart';
import '../util/date_utils.dart';
import '../screens/appointment/appointment_detail_page.dart';

class ScheduleDayView extends StatelessWidget {
  final DateTime day;
  final List<Appointment> appointments;

  const ScheduleDayView(
      {super.key, required this.day, required this.appointments});

  @override
  Widget build(BuildContext context) {
    final slots = halfHourSlots(day);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slotStart = slots[index];
        final slotEnd = slotStart.add(const Duration(minutes: 30));

        // Try to find a matching appointment for this slot
        Appointment? appt;
        for (final a in appointments) {
          if (a.start.hour == slotStart.hour &&
              a.start.minute == slotStart.minute) {
            appt = a;
            break;
          }
        }
        final hasAppt = appt != null;

        return Card(
          color:
              hasAppt ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(formatTimeRange(slotStart, slotEnd)),
            subtitle: hasAppt
                ? Text(
                    '${appt!.patient.name} • ${appt.patient.insuranceProvider} • ${appt.reason}')
                : const Text('Available'),
            trailing: hasAppt ? const Icon(Icons.chevron_right) : null,
            onTap: hasAppt
                ? () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AppointmentDetailPage(appointment: appt!),
                    ));
                  }
                : null,
          ),
        );
      },
    );
  }
}
