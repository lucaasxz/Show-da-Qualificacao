import '../models/question.dart';

/// Distribuição oficial de questões por matéria — Teórica Geral (IS-N1)
/// Fonte: tabela invariável fornecida pelo cliente.
const teoricaGeralGroups = [
  ExamGroup(code: 'CONS',  name: 'Consumíveis de Soldagem',             requiredCount: 4),
  ExamGroup(code: 'DOCS',  name: 'Documentos Técnicos de Soldagem',     requiredCount: 3),
  ExamGroup(code: 'ENSM',  name: 'Ensaios Mecânicos',                   requiredCount: 4),
  ExamGroup(code: 'ENSND', name: 'Ensaios Não Destrutivos',             requiredCount: 4),
  ExamGroup(code: 'INST',  name: 'Instrumental e Técnicas de Medidas',  requiredCount: 3),
  ExamGroup(code: 'INTR',  name: 'Introdução',                          requiredCount: 2),
  ExamGroup(code: 'MATB',  name: 'Materiais de Base',                   requiredCount: 4),
  ExamGroup(code: 'META',  name: 'Metalurgia da Soldagem',              requiredCount: 4),
  ExamGroup(code: 'PROC',  name: 'Processos de Soldagem',               requiredCount: 5),
  ExamGroup(code: 'PROT',  name: 'Proteção na Soldagem',                requiredCount: 2),
  ExamGroup(code: 'QUAL',  name: 'Qualificações',                       requiredCount: 4),
  ExamGroup(code: 'SIMB',  name: 'Simbologia de Soldagem',              requiredCount: 5),
  ExamGroup(code: 'TENS',  name: 'Tensões e Deformações na Soldagem',   requiredCount: 3),
  ExamGroup(code: 'TERM',  name: 'Terminologia de Soldagem',            requiredCount: 3),
]; // Total: 50 questões por prova
