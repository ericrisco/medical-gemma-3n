import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import '../models/medical_question.dart';
import '../services/medical_triage_service.dart';
import '../services/gemma_model_service.dart';
import 'chat_screen.dart';

class FirstAidGuideScreen extends StatefulWidget {
  const FirstAidGuideScreen({super.key});

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen>
    with TickerProviderStateMixin {
  final MedicalTriageService _triageService = MedicalTriageService();
  final GemmaModelService _gemmaService = GemmaModelService();
  
  dynamic _session;
  MedicalQuestion? _currentQuestion;
  String? _aiGeneratedQuestion;
  List<String>? _aiGeneratedAnswers;
  bool _isLoading = false;
  bool _isModelReady = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _triageService.reset();
    _currentQuestion = _triageService.currentQuestion;
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
    
    _slideController.forward();
    _fadeController.forward();
    
    // Initialize session using global model service
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    print('🚀 FIRST AID: Starting session initialization...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Create session using global model service
      print('📝 FIRST AID: Creating session...');
      _session = await _gemmaService.createSession(
        temperature: 0.7,
        randomSeed: 1,
        topK: 40,
      );
      
      if (mounted) {
        setState(() {
          _isModelReady = true;
          _isLoading = false;
        });
      }
      print('✅ FIRST AID: Session initialization completed successfully!');
    } catch (e) {
      print('💥 FIRST AID: Session initialization failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isModelReady = false;
        });
      }
      throw Exception('CRITICAL ERROR: Session initialization failed - $e');
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _cleanupResources(); // Note: This is async but dispose can't await
    super.dispose();
  }

  Future<void> _handleAnswer(String answerId, [int? aiSeverity]) async {
    print('🔄 FIRST AID: Handle answer started - ID: $answerId');
    setState(() {
      _isLoading = true;
    });

    // Record the response
    print('📝 FIRST AID: Recording response...');
    if (_triageService.isInInitialPhase) {
      print('📋 FIRST AID: Recording initial phase response');
      _triageService.recordResponse(answerId);
    } else if (_aiGeneratedQuestion != null) {
      print('📋 FIRST AID: Recording AI-generated response');
      final answerText = _aiGeneratedAnswers![int.parse(answerId)];
      _triageService.recordAIResponse(_aiGeneratedQuestion!, answerText, aiSeverity ?? 2);
    }

    // Check if we need to continue with initial questions
    if (_triageService.isInInitialPhase) {
      print('➡️ FIRST AID: Still in initial phase, moving to next question');
      setState(() {
        _currentQuestion = _triageService.currentQuestion;
        _isLoading = false;
      });
      _animateToNext();
      return;
    }
    
    // After 3 initial questions, let AI agent decide next step
    final totalResponses = _triageService.responses.length;
    const maxQuestions = 12; // 3 fixed + up to 9 AI maximum
    
    if (totalResponses >= maxQuestions) {
      // Reached maximum questions, open chat with summary
      print('🎯 FIRST AID: Maximum questions reached, opening chat with summary...');
      await _openChatWithSummary();
    } else if (totalResponses >= 3) {
      // After 3+ questions, let AI agent decide if more info needed
      print('🤖 FIRST AID: AI agent evaluating if more info is needed...');
      await _evaluateWithAIAgent();
    }
  }

  void _animateToNext() {
    _slideController.reset();
    _fadeController.reset();
    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _evaluateWithAIAgent() async {
    if (!_isModelReady || _session == null) {
      print('❌ FIRST AID: Session not ready, reinitializing...');
      await _initializeSession();
      if (!_isModelReady || _session == null) {
        throw Exception('CRITICAL ERROR: AI agent evaluation impossible - Session not initialized');
      }
    }

    try {
      print('🤖 FIRST AID: AI agent evaluating patient information...');
      
      final prompt = '''${_triageService.responses.length} questions asked so far. 

To provide accurate medical assessment, I need comprehensive information about:
- Exact symptoms and their severity
- Timeline and progression 
- Patient's medical history
- Current medications
- Vital signs if available
- Location and circumstances
- Previous treatments attempted

Do I have SUFFICIENT DETAILED information for a thorough medical assessment?

Reply ONLY: true OR false''';

      print('📤 FIRST AID: Sending evaluation prompt...');
      final message = flutter_gemma.Message.text(text: prompt, isUser: true);
      await _session!.addQueryChunk(message);
      
      final response = await _session!.getResponse().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('💥 FIRST AID: EVALUATION TIMEOUT - opening chat');
          return 'true'; // Force chat opening on timeout
        },
      );
      print('✅ FIRST AID: AI agent decision received: $response');
      
      // Parse simple true/false response - be more strict
      final cleanResponse = response.trim().toLowerCase();
      // Only consider it sufficient if:
      // 1. AI explicitly says true AND we have at least 6 questions
      // 2. OR we've reached the absolute maximum of 9 questions
      final explicitlyTrue = cleanResponse.contains('true');
      final hasMinimumQuestions = _triageService.responses.length >= 6;
      final reachedMaximum = _triageService.responses.length >= 9;
      final sufficientInfo = (explicitlyTrue && hasMinimumQuestions) || reachedMaximum;
      
      print('🎯 FIRST AID: AI agent decision - sufficient_info: $sufficientInfo');
      
      if (sufficientInfo) {
        // AI agent says we have enough info, open chat
        print('✅ FIRST AID: AI agent says sufficient info, opening chat...');
        await _openChatWithSummary();
      } else {
        // AI agent wants more info, call question generation agent
        print('❓ FIRST AID: AI agent wants more info, calling question generator...');
        await _generateAIQuestion();
      }
      
    } catch (e) {
      print('💥 FIRST AID: Error in AI agent evaluation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // On error, just open chat with what we have
      await _openChatWithSummary();
    }
  }

  Future<void> _generateAIQuestion() async {
    if (!_isModelReady || _session == null) {
      print('❌ FIRST AID: Session not ready, reinitializing...');
      await _initializeSession();
      if (!_isModelReady || _session == null) {
        throw Exception('CRITICAL ERROR: AI question generation impossible - Session not initialized');
      }
    }

    try {
      print('🤖 FIRST AID: Question generation agent creating next question...');
      
      // Get detailed history of questions and answers
      final responses = _triageService.responses;
      final questionHistory = StringBuffer();
      questionHistory.write('Previous questions and answers:\n');
      
      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        questionHistory.write('Q${i+1}: ${response.questionText}\n');
        questionHistory.write('A${i+1}: ${response.answerText}\n\n');
      }
      
      final prompt = '''${questionHistory.toString()}

Generate ONE medical follow-up question based on above conversation.

JSON:
{"question": "Next medical question?", "answers": ["Option 1", "Option 2", "Option 3", "Option 4"]}''';

      print('📤 FIRST AID: Sending question generation prompt to AI...');
      final message = flutter_gemma.Message.text(text: prompt, isUser: true);
      await _session!.addQueryChunk(message);
      
      final response = await _session!.getResponse().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('💥 FIRST AID: QUESTION GENERATION TIMEOUT - opening chat');
          throw Exception('Question generation timeout - opening chat');
        },
      );
      print('✅ FIRST AID: Question generation agent response received: $response');
      print('🔍 FIRST AID: Full response length: ${response.length}');
      print('🔍 FIRST AID: Response content: "${response.replaceAll('\n', '\\n')}"');
      
      // Parse JSON response with better error handling
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      print('🔍 FIRST AID: JSON start: $jsonStart, end: $jsonEnd');
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        print('🔍 FIRST AID: Extracted JSON: $jsonStr');
        
        try {
          final parsed = json.decode(jsonStr);
          print('🔍 FIRST AID: Parsed JSON: $parsed');
          
          // Validate the parsed JSON has required fields
          if (parsed is Map && parsed.containsKey('question') && parsed.containsKey('answers')) {
            final question = parsed['question']?.toString() ?? '';
            final answers = parsed['answers'];
            
            if (question.isNotEmpty && answers is List && answers.isNotEmpty) {
              setState(() {
                _aiGeneratedQuestion = question;
                _aiGeneratedAnswers = answers.map((e) => e.toString()).toList();
                _currentQuestion = null;
                _isLoading = false;
              });
              
              _animateToNext();
              return; // Success, exit the function
            }
          }
        } catch (jsonError) {
          print('💥 FIRST AID: JSON decode error: $jsonError');
        }
      }
      
      // If we reach here, parsing failed
      throw Exception('CRITICAL ERROR: Question generation agent returned invalid JSON response');
      
    } catch (e) {
      print('💥 FIRST AID: Error in question generation agent: $e');
      
      // If question generation fails, just open chat with what we have
      print('🔄 FIRST AID: Question generation failed, opening chat...');
      await _openChatWithSummary();
    }
  }

  Future<void> _openChatWithSummary() async {
    print('💬 FIRST AID: Creating summary for chat...');
    
    // Create summary of questions and answers
    final responses = _triageService.responses;
    final summaryBuffer = StringBuffer();
    
    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      summaryBuffer.write('${response.questionText} - ${response.answerText}');
      if (i < responses.length - 1) {
        summaryBuffer.write(' | ');
      }
    }
    
    final summary = summaryBuffer.toString();
    print('📋 FIRST AID: Summary created: $summary');
    
    // Clean up resources before navigating
    await _cleanupResources();
    
    // Wait a bit more to ensure cleanup is complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navigate to chat with the summary
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(initialMessage: summary),
      ),
    );
  }

  Future<void> _cleanupResources() async {
    print('🧹 FIRST AID: Cleaning up session resources...');
    try {
      if (_session != null) {
        // Close the session properly to free up resources
        print('🔚 FIRST AID: Closing session...');
        await _session!.close();
        _session = null;
      }
      // Reset state
      _isModelReady = false;
      print('✅ FIRST AID: Session cleaned up successfully');
    } catch (e) {
      print('⚠️ FIRST AID: Error during cleanup: $e');
    }
  }


  int _getQuestionNumber() {
    if (_triageService.isInInitialPhase) {
      return _triageService.responses.length + 1;
    } else {
      return _triageService.responses.length + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with progress
                _buildHeader(),
                
                // Main content
                Expanded(
                  child: _buildQuestionScreen(),
                ),
                
                // Loading indicator
                if (_isLoading) _buildLoadingIndicator(),
              ],
            ),
          ),
          
          // Full screen overlay when model is not ready
          if (!_isModelReady) _buildModelLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currentQuestionNum = _getQuestionNumber();
    // Progress: maximum 12 questions (3 fixed + up to 9 AI)
    const maxQuestions = 12;
    final progress = (_triageService.responses.length / maxQuestions).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _isModelReady ? () => Navigator.of(context).pop() : null,
                icon: const Icon(Icons.arrow_back_ios),
                color: _isModelReady ? Colors.grey[600] : Colors.grey[300],
              ),
              const Spacer(),
              Text(
                'Question $currentQuestionNum',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    String questionText;
    List<Widget> answerWidgets;

    if (_currentQuestion != null) {
      // Fixed initial questions
      questionText = _currentQuestion!.question;
      answerWidgets = _currentQuestion!.answers.map((answer) {
        return _buildAnswerButton(
          answer.text,
          () => _handleAnswer(answer.id),
          _getSeverityColor(answer.severity),
        );
      }).toList();
    } else if (_aiGeneratedQuestion != null && _aiGeneratedAnswers != null) {
      // AI-generated question
      questionText = _aiGeneratedQuestion!;
      answerWidgets = _aiGeneratedAnswers!.asMap().entries.map((entry) {
        final index = entry.key;
        final answerText = entry.value;
        return _buildAnswerButton(
          answerText,
          () => _handleAnswer(index.toString(), index + 1), // Severity based on order
          _getSeverityColor(index + 1),
        );
      }).toList();
    } else {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Answers
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: answerWidgets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final widget = entry.value;
                  
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Interval(
                        0.1 + (index * 0.1),
                        0.5 + (index * 0.1),
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(
                          0.2 + (index * 0.1),
                          0.6 + (index * 0.1),
                        ),
                      )),
                      child: widget,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String text, VoidCallback onTap, Color color) {
    final isEnabled = _isModelReady && !_isLoading;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled ? color.withOpacity(0.3) : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.grey[800] : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildModelLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Doctor Image
            Container(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/thedoctor.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Initializing Medical AI...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Please wait while we prepare your emergency assistant',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing responses...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }
}