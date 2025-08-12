import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:convert';
import '../../../core/models/patient.dart';
import '../../../widgets/tsne_scatter.dart';

class CurrentVisitTab extends StatefulWidget {
  const CurrentVisitTab({super.key});

  @override
  State<CurrentVisitTab> createState() => _CurrentVisitTabState();
}

class _CurrentVisitTabState extends State<CurrentVisitTab>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();

  bool _recording = false;
  bool _processing = false;
  String? _audioPath;
  List<String> _transcript = [];

  // TODO: point this to your Python script
  // Example: r'C:\Users\you\Documents\transcribe.py'
  static const String _pythonScriptPath =
      r'C:\Users\XXXX\XXXX\XXXX\aws_healthcare_ai_final_project\aws-transcribe-2.py';

  // Optional: specify Python binary if "python" is not in PATH.
  // Example: r'C:\Users\you\AppData\Local\Programs\Python\Python311\python.exe'
  static const String _pythonExe = 'python';

  // Add to the top of _CurrentVisitTabState
  List<KeywordPoint> _tsnePoints = [];
  String _aiAnalysis = '';
  // Path to the tsne script
  static const String _tsneScriptPath =
      r'C:\Users\XXXX\XXXX\XXXX\aws_healthcare_ai_final_project\tsne_and_analysis.py';

  String _aiSummary = '';
  Map<String, dynamic> _aiEntities = {};
  String _aiFollowUp = '';

  // Path to the Python analysis script
  static const String _analysisScriptPath =
      r'C:\Users\XXXX\XXXX\XXXX\Code\aws_healthcare_ai_final_project\analyze_transcript_with_llm.py';

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _targetWavPath() async {
    final Directory base = Platform.isWindows
        ? Directory(
            r'C:\Users\XXXX\XXXX\XXXX\Code\aws_healthcare_ai_final_project')
        : (await getTemporaryDirectory());
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    return Platform.isWindows
        ? '${base.path}\\visit_$ts.wav'
        : '${base.path}/visit_$ts.wav';
  }

  Future<void> _startRecording() async {
    final canRecord = await _recorder.hasPermission();
    if (!canRecord) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission not granted')),
        );
      }
      return;
    }

    final path = await _targetWavPath();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        numChannels: 1,
        sampleRate: 48000,
      ),
      path: path,
    );

    setState(() {
      _audioPath = path;
      _recording = true;
      _processing = false;
      _transcript.clear();
    });
  }

  Future<String> _postProcessWav(String inputPath) async {
  final outPath = inputPath.replaceAll('.wav', '_clean16k.wav');
  final result = await Process.run(
    'C:\\ffmpeg-7.1.1-essentials_build\\bin\\ffmpeg.exe', [
      '-y',
      '-i', inputPath,
      '-af', 'highpass=f=100,lowpass=f=8000,afftdn=nf=-20',
      '-ar', '16000',
      '-ac', '1',
      outPath
    ],
    runInShell: true,
  );
  if (result.exitCode != 0) {
    debugPrint('FFmpeg error: ${result.stderr}');
    return inputPath; // fall back
  }
  return outPath;
}


  Future<void> _runTsneAnalysis(String text) async {
    try {
      // Write transcript to a temp .txt
      final tempDir = Directory(
          r'C:\Users\XXXX\XXXX\XXXX\Code\aws_healthcare_ai_final_project');
      final txtPath = Platform.isWindows
          ? '${tempDir.path}\\transcript.txt'
          : '${tempDir.path}/transcript.txt';
      final file = File(txtPath);
      await file.writeAsString(text, flush: true);

      final result = await Process.run(
        _pythonExe,
        [_tsneScriptPath, '--input', txtPath],
        runInShell: true,
        workingDirectory: File(_tsneScriptPath).parent.path,
      );

      if (result.exitCode == 0) {
        final out = (result.stdout ?? '').toString();
        try {
          final Map<String, dynamic> obj = jsonDecode(out);
          final pts = (obj['points'] as List<dynamic>? ?? [])
              .map((e) => KeywordPoint(
                    label: (e['label'] ?? '').toString(),
                    x: (e['x'] as num).toDouble(),
                    y: (e['y'] as num).toDouble(),
                  ))
              .toList();
          setState(() {
            _tsnePoints = pts;
            _aiAnalysis = (obj['analysis'] ?? '').toString();
          });
        } catch (e) {
          setState(() {
            _tsnePoints = [];
            _aiAnalysis = 'Could not parse t-SNE output: $e\n$out';
          });
        }
      } else {
        setState(() {
          _tsnePoints = [];
          _aiAnalysis =
              't-SNE script failed:\n${(result.stderr ?? '').toString()}';
        });
      }
    } catch (e) {
      setState(() {
        _tsnePoints = [];
        _aiAnalysis = 't-SNE/analysis error: $e';
      });
    }
  }

  Future<void> _runChatGptAnalysis(String text) async {
    try {
      // Write transcript to temp file so command lines stay short
      final dir = Directory(
          r'C:\Users\XXXX\XXXX\XXXX\Code\aws_healthcare_ai_final_project');
      final txtPath = Platform.isWindows
          ? '${dir.path}\\transcript.txt'
          : '${dir.path}/transcript.txt';
      await File(txtPath).writeAsString(text, flush: true);

      final result = await Process.run(
        _pythonExe,
        [_analysisScriptPath, '--input', txtPath],
        runInShell: true,
        workingDirectory: File(_analysisScriptPath).parent.path,
      );

      if (result.exitCode == 0) {
        final out = (result.stdout ?? '').toString().trim();
        try {
          final Map<String, dynamic> obj = jsonDecode(out);
          setState(() {
            _aiSummary = (obj['summary'] ?? '').toString();
            final ent = obj['entities'];
            _aiEntities = (ent is Map) ? Map<String, dynamic>.from(ent) : {};
            _aiFollowUp = (obj['follow_up'] ?? '').toString();
          });
        } catch (e) {
          setState(() {
            _aiSummary = '';
            _aiEntities = {};
            _aiFollowUp = 'Could not parse analysis JSON: $e\n$out';
          });
        }
      } else {
        setState(() {
          _aiSummary = '';
          _aiEntities = {};
          _aiFollowUp =
              'Analysis script failed:\n${(result.stderr ?? '').toString()}';
        });
      }
    } catch (e) {
      setState(() {
        _aiSummary = '';
        _aiEntities = {};
        _aiFollowUp = 'Analysis error: $e';
      });
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _processing = true; // show spinner
    });

    final audioToProcess = await _postProcessWav(path ?? _audioPath!);
    if (audioToProcess == null) {
      setState(() {
        _processing = false;
        _transcript = ['No audio file to process.'];
      });
      return;
    }

    try {
      final result = await Process.run(
        _pythonExe,
        [_pythonScriptPath, audioToProcess, '--region', 'us-east-1'],
        runInShell: true,
        workingDirectory: File(_pythonScriptPath).parent.path,
      );

      if (result.exitCode == 0) {
        final stdoutStr = (result.stdout ?? '').toString();
        String text;
        try {
          final Map<String, dynamic> obj = jsonDecode(stdoutStr);
          text = (obj['transcript'] ?? '').toString();
        } catch (_) {
          text = stdoutStr.trim();
        }

        setState(() {
          _transcript = text.isEmpty ? ['(No transcript returned)'] : [text];
        });

        // NEW: kick off t-SNE & analysis
        await _runTsneAnalysis(text);
        await _runChatGptAnalysis(text);

        setState(() {
          _processing = false;
        });
      } else {
        setState(() {
          _transcript = [
            'Transcription failed:',
            (result.stderr ?? '').toString()
          ];
          _processing = false;
        });
      }
    } catch (e) {
      setState(() {
        _transcript = ['Transcription error: $e'];
        _processing = false;
      });
    }
  }

  void _toggleRecording() {
    if (_recording) {
      _stopRecordingAndProcess();
    } else {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    final bigButton = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: Icon(_recording ? Icons.stop_circle : Icons.mic, size: 48),
          label: Text(
            _recording ? 'Stop Recording' : 'Start Recording',
            style: const TextStyle(fontSize: 28),
          ),
          onPressed: _processing ? null : _toggleRecording,
          style:
              ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(200)),
        ),
      ),
    );

    final transcriptPane = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _processing
              ? const _SpinnerWithNote(key: ValueKey('spinner'))
              : Padding(
                  key: const ValueKey('content'),
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1) Transcript
                        Text('Transcript',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        ..._transcript.map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child:
                                  Text(t, style: const TextStyle(fontSize: 16)),
                            )),
                        const SizedBox(height: 16),

                        // 2) t-SNE
                        Text('t-SNE keyword map',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 260,
                          child: _tsnePoints.isEmpty
                              ? const Text('(No t-SNE points)')
                              : TsneScatter(points: _tsnePoints),
                        ),
                        const SizedBox(height: 16),

                        // 3) AI analysis
                        Text('AI analysis',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (_aiSummary.isNotEmpty) ...[
                          Text('Summary',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(_aiSummary,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 12),
                        ],

// Entities
                        if (_aiEntities.isNotEmpty) ...[
                          Text('Entities',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _aiEntities.entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Text('• ${e.key}: ${e.value}',
                                          style: const TextStyle(fontSize: 16)),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

// Follow-up
                        Text('Follow-up',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          _aiFollowUp.isEmpty
                              ? '(No recommendation yet)'
                              : _aiFollowUp,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: bigButton),
          Expanded(child: transcriptPane),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(child: bigButton),
          Expanded(child: transcriptPane),
        ],
      );
    }
  }
}

class _SpinnerWithNote extends StatelessWidget {
  const _SpinnerWithNote({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Processing audio…', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
