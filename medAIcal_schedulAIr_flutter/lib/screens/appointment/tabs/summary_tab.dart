import 'package:flutter/material.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/models/patient.dart';
import '../../../widgets/tsne_scatter.dart';

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Patient>>(
      future: MockData.loadPatientsFromDb(), // <-- async DB call
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final patients = snapshot.data ?? [];
        if (patients.isEmpty) {
          return const Center(child: Text('No patients found.'));
        }

        // For now just take the first patient
        final patient = patients.first;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Past Visit Notes',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: patient.pastNotes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: Text(patient.pastNotes[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Keyword Map (t-SNE)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: TsneScatter(points: patient.keywordMap),
              ),
            ],
          ),
        );
      },
    );
  }
}
