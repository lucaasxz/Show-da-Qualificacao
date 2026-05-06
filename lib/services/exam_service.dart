import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../data/exam_config.dart';

class ExamService {
  static final ExamService _instance = ExamService._();
  factory ExamService() => _instance;
  ExamService._();

  List<Question>? _bankCache;

  Future<List<Question>> _loadBank(String examType) async {
    if (_bankCache != null) return _bankCache!;
    final raw = await rootBundle.loadString('assets/questions/$examType.json');
    final list = jsonDecode(raw) as List;
    _bankCache = list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
    return _bankCache!;
  }

  /// Gera uma prova aleatória respeitando a distribuição de [groups].
  /// Lança [InsufficientQuestionsException] se algum grupo não tiver
  /// questões suficientes no banco.
  Future<List<Question>> generateExam({
    required String examType,
    required List<ExamGroup> groups,
  }) async {
    final bank = await _loadBank(examType);
    final rng = Random();
    final exam = <Question>[];

    for (final group in groups) {
      final pool = bank.where((q) => q.group == group.code).toList();

      if (pool.length < group.requiredCount) {
        throw InsufficientQuestionsException(
          group: group.name,
          available: pool.length,
          required: group.requiredCount,
        );
      }

      pool.shuffle(rng);
      exam.addAll(pool.take(group.requiredCount));
    }

    exam.shuffle(rng);
    return exam;
  }

  Future<List<Question>> generateTeoricaGeral() => generateExam(
        examType: 'teorica_geral',
        groups: teoricaGeralGroups,
      );

  void clearCache() => _bankCache = null;
}

class InsufficientQuestionsException implements Exception {
  final String group;
  final int available;
  final int required;

  InsufficientQuestionsException({
    required this.group,
    required this.available,
    required this.required,
  });

  @override
  String toString() =>
      'Grupo "$group": $available questões disponíveis, $required necessárias.';
}
