import 'package:flutter/material.dart';
import '../../core/models/appointment.dart';
import '../../util/date_utils.dart';
import 'tabs/summary_tab.dart';
import 'tabs/current_visit_tab.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appointment.patient.name),
          bottom: const TabBar(tabs: [
            Tab(text: 'Summary'),
            Tab(text: 'Current Visit'),
          ]),
        ),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                      child: _infoTile(
                          'Patient', appointment.patient.name, Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _infoTile('Insurance',
                          appointment.patient.insuranceProvider, Icons.shield)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _infoTile(
                          'Time',
                          formatTimeRange(appointment.start, appointment.end),
                          Icons.access_time)),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const TabBarView(
                children: [
                  SummaryTab(),
                  CurrentVisitTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF3F5F8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
