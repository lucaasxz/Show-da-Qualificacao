class Question {
  final String id;
  final String group;
  final String text;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.id,
    required this.group,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        group: json['group'] as String,
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
      };
}

class ExamGroup {
  final String code;
  final String name;
  final int requiredCount;

  const ExamGroup({
    required this.code,
    required this.name,
    required this.requiredCount,
  });
}
