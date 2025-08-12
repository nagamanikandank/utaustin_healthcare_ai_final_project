import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/simple_bar_chart.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _loading = false;
  double _accuracy = 0.0;
  List<String> _classes = [];
  Map<String, List<Map<String, dynamic>>> _featuresByClass = {};
  String? _selectedClass;

  static const String _pythonExe = 'python';
  static const String _mlScriptPath = r'C:\Users\XXXX\XXXX\XXXX\aws_healthcare_ai_final_project\ml_insurance_classifier.py';

  @override
  void initState() {
    super.initState();
    _runMl();
  }

  Future<void> _runMl() async {
    setState(() => _loading = true);
    try {
      final result = await Process.run(
        _pythonExe,
        [
          _mlScriptPath,
          '--host','localhost',
          '--db','postgres',
          '--user','postgres',
          '--password','password',
          '--port','5432',
        ],
        runInShell: true,
        workingDirectory: File(_mlScriptPath).parent.path,
      );

      if (result.exitCode == 0) {
        final out = (result.stdout ?? '').toString();
        final obj = jsonDecode(out) as Map<String, dynamic>;
        final classes = (obj['classes'] as List).map((e) => e.toString()).toList();
        final features = <String, List<Map<String, dynamic>>>{};
        final fObj = obj['features'] as Map<String, dynamic>? ?? {};

        for (final entry in fObj.entries) {
          final cls = entry.key;
          final list = (entry.value as List).map<Map<String, dynamic>>((e) => {
            "label": e["label"].toString(),
            "weight": (e["weight"] as num).toDouble(),
          }).toList();
          features[cls] = list;
        }

        setState(() {
          _accuracy = (obj['accuracy'] as num?)?.toDouble() ?? 0.0;
          _classes = classes;
          _featuresByClass = features;
          _selectedClass = classes.isNotEmpty ? classes.first : null;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        _showSnack('ML script failed:\n${(result.stderr ?? '').toString()}');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error running ML: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bars = (_selectedClass != null && _featuresByClass[_selectedClass!] != null)
        ? _featuresByClass[_selectedClass!]!
            .map((m) => BarItem(m['label'] as String, (m['weight'] as double)))
            .toList()
        : <BarItem>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('medAIcal schedulAIr', style: TextStyle(fontWeight: FontWeight.bold))),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Schedule (Home)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_graph),
                title: const Text('Analysis'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insurance classifier', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'This chart shows the top keyword labels most strongly associated '
                    'with each insurance provider based on past patient keyword data. '
                    'Bar lengths represent the relative importance (model weight) of '
                    'each keyword in predicting the patient''s insurer.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text('Accuracy: ${_accuracy.toStringAsFixed(3)}'),
                  const SizedBox(height: 12),
                  if (_classes.isNotEmpty)
                    Row(
                      children: [
                        const Text('Class:'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedClass,
                          items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedClass = v),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _runMl,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Re-run'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SimpleBarChart(items: bars),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
