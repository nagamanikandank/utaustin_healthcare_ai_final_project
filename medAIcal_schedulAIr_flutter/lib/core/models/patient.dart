class KeywordPoint {
  final String label;
  final double x; // normalized -1..1
  final double y; // normalized -1..1

  const KeywordPoint({required this.label, required this.x, required this.y});

  factory KeywordPoint.fromMap(Map<String, dynamic> m) => KeywordPoint(
      label: m['label'] as String,
      x: (m['x'] as num).toDouble(),
      y: (m['y'] as num).toDouble());
}

class Patient {
  final String id;
  final String name;
  final String insuranceProvider;
  final List<String> pastNotes;
  final List<KeywordPoint> keywordMap; // mocked t-SNE coordinates

  const Patient({
    required this.id,
    required this.name,
    required this.insuranceProvider,
    required this.pastNotes,
    required this.keywordMap,
  });
}
