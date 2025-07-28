class MedicalQuestion {
  final String id;
  final String question;
  final List<MedicalAnswer> answers;
  final bool isFixed; // true for initial 4 questions, false for AI-generated
  
  const MedicalQuestion({
    required this.id,
    required this.question,
    required this.answers,
    this.isFixed = false,
  });
}

class MedicalAnswer {
  final String id;
  final String text;
  final int severity; // 1-5 scale for triage purposes
  
  const MedicalAnswer({
    required this.id,
    required this.text,
    required this.severity,
  });
}

class MedicalResponse {
  final String questionId;
  final String answerId;
  final String questionText;
  final String answerText;
  final int severity;
  final DateTime timestamp;
  
  MedicalResponse({
    required this.questionId,
    required this.answerId,
    required this.questionText,
    required this.answerText,
    required this.severity,
    required this.timestamp,
  });
}

class DiagnosisState {
  final bool needsMoreInfo;
  final String? diagnosis;
  final String? nextQuestion;
  final List<String>? nextAnswers;
  final int overallSeverity;
  
  DiagnosisState({
    required this.needsMoreInfo,
    this.diagnosis,
    this.nextQuestion,
    this.nextAnswers,
    required this.overallSeverity,
  });
}