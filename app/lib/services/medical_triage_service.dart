import 'dart:convert';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import '../models/medical_question.dart';

class MedicalTriageService {
  static final MedicalTriageService _instance = MedicalTriageService._internal();
  factory MedicalTriageService() => _instance;
  MedicalTriageService._internal();

  // 3 fixed initial questions that an emergency doctor would ask
  static const List<MedicalQuestion> _initialQuestions = [
    MedicalQuestion(
      id: 'consciousness',
      question: 'Is the patient conscious and alert?',
      isFixed: true,
      answers: [
        MedicalAnswer(id: 'fully_conscious', text: 'Fully conscious and alert', severity: 1),
        MedicalAnswer(id: 'confused', text: 'Conscious but confused or disoriented', severity: 3),
        MedicalAnswer(id: 'drowsy', text: 'Drowsy but responds to stimuli', severity: 4),
        MedicalAnswer(id: 'unconscious', text: 'Unconscious or unresponsive', severity: 5),
      ],
    ),
    MedicalQuestion(
      id: 'breathing',
      question: 'How is the patient\'s breathing?',
      isFixed: true,
      answers: [
        MedicalAnswer(id: 'normal_breathing', text: 'Normal breathing, no difficulty', severity: 1),
        MedicalAnswer(id: 'slight_difficulty', text: 'Slight difficulty breathing', severity: 2),
        MedicalAnswer(id: 'labored_breathing', text: 'Labored or rapid breathing', severity: 4),
        MedicalAnswer(id: 'severe_difficulty', text: 'Severe difficulty or cannot breathe', severity: 5),
      ],
    ),
    MedicalQuestion(
      id: 'location_resources',
      question: 'What medical resources are available at your location?',
      isFixed: true,
      answers: [
        MedicalAnswer(id: 'hospital_near', text: 'Hospital or medical facility nearby', severity: 1),
        MedicalAnswer(id: 'hospital_far', text: 'Hospital available but far away', severity: 2),
        MedicalAnswer(id: 'no_medical_access', text: 'No access to medical facilities', severity: 3),
        MedicalAnswer(id: 'no_basic_resources', text: 'No electricity, water, or basic resources', severity: 4),
      ],
    ),
  ];

  int _currentQuestionIndex = 0;
  final List<MedicalResponse> _responses = [];

  // Getters
  List<MedicalQuestion> get initialQuestions => _initialQuestions;
  List<MedicalResponse> get responses => List.unmodifiable(_responses);
  bool get isInInitialPhase => _currentQuestionIndex < _initialQuestions.length;
  
  MedicalQuestion? get currentQuestion {
    if (_currentQuestionIndex < _initialQuestions.length) {
      return _initialQuestions[_currentQuestionIndex];
    }
    return null; // Will be handled by AI-generated questions
  }

  // Reset the service for a new patient
  void reset() {
    _currentQuestionIndex = 0;
    _responses.clear();
  }

  // Record a response and move to next question
  void recordResponse(String answerId) {
    if (_currentQuestionIndex < _initialQuestions.length) {
      final question = _initialQuestions[_currentQuestionIndex];
      final answer = question.answers.firstWhere((a) => a.id == answerId);
      
      final response = MedicalResponse(
        questionId: question.id,
        answerId: answer.id,
        questionText: question.question,
        answerText: answer.text,
        severity: answer.severity,
        timestamp: DateTime.now(),
      );
      
      _responses.add(response);
      _currentQuestionIndex++;
    }
  }

  // Calculate overall severity from responses
  int calculateOverallSeverity() {
    if (_responses.isEmpty) return 1;
    
    final severities = _responses.map((r) => r.severity).toList();
    final maxSeverity = severities.reduce((a, b) => a > b ? a : b);
    final avgSeverity = severities.reduce((a, b) => a + b) / severities.length;
    
    // Weight towards higher severity
    return ((maxSeverity * 0.7) + (avgSeverity * 0.3)).round();
  }

  // Generate context string for AI
  String generateContextForAI() {
    final buffer = StringBuffer();
    buffer.write('Patient: ');
    
    for (int i = 0; i < _responses.length; i++) {
      final r = _responses[i];
      buffer.write('${r.answerText}(${r.severity})');
      if (i < _responses.length - 1) buffer.write(', ');
    }
    
    return buffer.toString();
  }

  // Private method kept for internal use
  String _generateContextForAI() => generateContextForAI();

  // Use Gemma to determine next step
  Future<DiagnosisState> evaluateWithAI(dynamic session) async {
    try {
      final context = _generateContextForAI();
      print('📊 CONTEXT LENGTH: ${context.length} chars');
      
      final prompt = '''$context

Need more info? JSON:
{"needs_more_info": true, "next_question": "Question?", "answers": [{"text": "A1", "severity": 1}, {"text": "A2", "severity": 2}, {"text": "A3", "severity": 3}, {"text": "A4", "severity": 4}]}''';

      // Log the prompt being sent
      print('=== SENDING PROMPT TO GEMMA ===');
      print(prompt);
      print('=== END PROMPT ===');
      
      // Add the prompt as a message to the session
      print('📤 TRIAGE: Adding prompt to session...');
      final message = flutter_gemma.Message.text(text: prompt, isUser: true);
      await session.addQueryChunk(message);
      print('✅ TRIAGE: Prompt added, requesting response...');
      
      // Get response from session
      final response = await session.getResponse();
      print('✅ TRIAGE: Response received from AI');
      
      // Log the raw response received
      print('=== RAW GEMMA RESPONSE ===');
      print(response);
      print('=== END RAW RESPONSE ===');
      
      // Clean response to remove markdown code blocks
      String cleanedResponse = response;
      cleanedResponse = cleanedResponse.replaceAll('```json', '');
      cleanedResponse = cleanedResponse.replaceAll('```', '');
      cleanedResponse = cleanedResponse.trim();
      
      // Log cleaned response
      print('=== CLEANED RESPONSE ===');
      print(cleanedResponse);
      print('=== END CLEANED RESPONSE ===');
      
      // Parse the JSON response
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = cleanedResponse.substring(jsonStart, jsonEnd);
        print('=== EXTRACTED JSON ===');
        print(jsonStr);
        print('=== END EXTRACTED JSON ===');
        
        final parsed = json.decode(jsonStr);
        
        // Log parsed result
        print('=== PARSED RESULT ===');
        print('needs_more_info: ${parsed['needs_more_info']}');
        if (parsed['needs_more_info'] == true) {
          print('next_question: ${parsed['next_question']}');
          print('answers: ${parsed['answers']}');
        } else {
          print('assessment: ${parsed['assessment']}');
        }
        print('=== END PARSED RESULT ===');
        
        final needsMoreInfo = parsed['needs_more_info'] as bool;
        print('🎯 TRIAGE: AI decision - needs_more_info: $needsMoreInfo');
        
        if (needsMoreInfo) {
          print('❓ TRIAGE: AI wants more information, generating question...');
          final nextQuestion = parsed['next_question'] as String;
          print('📝 TRIAGE: Generated question: "$nextQuestion"');
          
          // Check if answers exist and log them
          if (parsed['answers'] != null) {
            final answersData = parsed['answers'] as List;
            print('📋 TRIAGE: Found ${answersData.length} answer options:');
            for (int i = 0; i < answersData.length; i++) {
              final answerObj = answersData[i];
              print('   ${i+1}. "${answerObj['text']}" (severity: ${answerObj['severity']})');
            }
            
            final answers = answersData.map((a) => a['text'] as String).toList();
            print('📋 TRIAGE: Extracted answers: ${answers.join(", ")}');
          } else {
            print('❌ TRIAGE: No answers found in AI response!');
          }
          
          final answers = parsed['answers'] != null 
              ? (parsed['answers'] as List).map((a) => a['text'] as String).toList()
              : <String>[];
          
          return DiagnosisState(
            needsMoreInfo: true,
            nextQuestion: nextQuestion,
            nextAnswers: answers,
            overallSeverity: calculateOverallSeverity(),
          );
        } else {
          // Triage says we have enough info, now consult the expert doctor
          print('✅ TRIAGE: AI says we have enough info - consulting expert doctor...');
          final expertAssessment = await _consultExpertDoctor(session);
          
          return DiagnosisState(
            needsMoreInfo: false,
            diagnosis: expertAssessment,
            overallSeverity: calculateOverallSeverity(),
          );
        }
      }
    } catch (e) {
      print('=== ERROR IN AI EVALUATION ===');
      print('Error: $e');
      print('=== END ERROR ===');
    }
    
    // Fallback if AI fails
    return DiagnosisState(
      needsMoreInfo: false,
      diagnosis: 'Unable to complete assessment. Please consult a medical professional immediately.',
      overallSeverity: 5,
    );
  }

  // Consult expert doctor for final assessment
  Future<String> _consultExpertDoctor(dynamic session) async {
    try {
      final context = _generateContextForAI();
      
      final expertPrompt = '''$context

You are a senior emergency medicine doctor. Based on the patient assessment above, provide your professional medical evaluation.

IMPORTANT: You must ALWAYS recommend seeking immediate medical attention at a hospital or emergency room, but also provide immediate stabilization measures that can be taken while waiting for or traveling to medical care.

Provide your assessment in the following format:

**PRIMARY CONCERN:** [Your primary diagnosis/concern]

**URGENCY LEVEL:** [Immediate Emergency / Urgent Care / Medical Attention Needed]

**IMMEDIATE ACTIONS:**
1. [First immediate action to stabilize patient]
2. [Second immediate action]
3. [Additional stabilization measures]

**SEEK MEDICAL CARE:** Call emergency services immediately / Go to emergency room now / Seek urgent medical attention

**WARNING SIGNS:** Watch for [specific symptoms that indicate worsening condition]

Respond with your complete assessment as plain text, not JSON.''';

      print('=== SENDING EXPERT DOCTOR PROMPT ===');
      print(expertPrompt);
      print('=== END EXPERT PROMPT ===');

      // Add the expert prompt as a message to the session
      final message = flutter_gemma.Message.text(text: expertPrompt, isUser: true);
      await session.addQueryChunk(message);
      
      // Get response from expert doctor
      final response = await session.getResponse();
      
      print('=== EXPERT DOCTOR RESPONSE ===');
      print(response);
      print('=== END EXPERT RESPONSE ===');
      
      return response.trim();
      
    } catch (e) {
      print('=== ERROR CONSULTING EXPERT DOCTOR ===');
      print('Error: $e');
      print('=== END EXPERT ERROR ===');
      
      // Fallback expert assessment
      final severity = calculateOverallSeverity();
      if (severity >= 4) {
        return '''**PRIMARY CONCERN:** High-severity medical emergency detected

**URGENCY LEVEL:** Immediate Emergency

**IMMEDIATE ACTIONS:**
1. Call emergency services immediately (911)
2. Keep patient conscious and monitor breathing
3. Control any bleeding with direct pressure
4. Do not give food or water

**SEEK MEDICAL CARE:** Call 911 immediately and go to emergency room

**WARNING SIGNS:** Loss of consciousness, difficulty breathing, severe bleeding, worsening pain''';
      } else {
        return '''**PRIMARY CONCERN:** Medical situation requiring attention

**URGENCY LEVEL:** Medical Attention Needed

**IMMEDIATE ACTIONS:**
1. Keep patient comfortable and calm
2. Monitor vital signs if possible
3. Note any changes in condition
4. Prepare for transport to medical facility

**SEEK MEDICAL CARE:** Seek medical attention promptly

**WARNING SIGNS:** Worsening symptoms, increased pain, changes in consciousness''';
      }
    }
  }

  // Record AI-generated response
  void recordAIResponse(String questionText, String answerText, int severity) {
    final response = MedicalResponse(
      questionId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      answerId: 'ai_answer_${DateTime.now().millisecondsSinceEpoch}',
      questionText: questionText,
      answerText: answerText,
      severity: severity,
      timestamp: DateTime.now(),
    );
    
    _responses.add(response);
  }
}