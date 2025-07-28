import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart' as local;
import '../services/emergency_service.dart';
import '../services/gemma_model_service.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  
  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final GemmaModelService _gemmaService = GemmaModelService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  dynamic _chat;
  List<local.Message> _messages = [];
  bool _isLoading = false;
  bool _isModelReady = false;
  bool _isGeneratingResponse = false;
  String? _errorMessage;
  bool _hasError = false;
  bool _isChatBusy = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize the chat using the global model service
  Future<void> _initializeModel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a chat instance (not session) for conversation history
      _chat = await _gemmaService.createChat(
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
      
      // Set system prompt for medical assistant
      await _setSystemPrompt();
      
      // Ensure chat is not busy after initialization
      if (mounted) {
        setState(() {
          _isChatBusy = false;
        });
      }
      
      
      // Handle initial message AFTER chat is completely ready
      if (widget.initialMessage != null) {
        _textController.text = widget.initialMessage!;
        _sendInitialMessageWhenReady();
      }
    } catch (e) {
      debugPrint('Chat initialization failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
          _isChatBusy = false;
        });
      }
    }
  }

  /// Set system prompt for medical assistant
  Future<void> _setSystemPrompt() async {
    try {
      _isChatBusy = true;
      // Get user's location and emergency numbers
      final locationInfo = await _getLocationInfo();
      
      final systemPrompt = '''You are a medical assistant in $locationInfo. Your role is to provide direct medical recommendations and help based on the information provided. 

IMPORTANT INSTRUCTIONS:
- Give specific, actionable medical advice and recommendations
- Provide step-by-step treatment guidance when appropriate
- Suggest immediate actions, medications, or treatments that can help
- Be direct and helpful - your goal is to assist with medical problems
- If symptoms suggest emergency care, provide immediate first aid instructions AND recommend seeking emergency care
- Never just say "consult a doctor" - always provide helpful recommendations first
- Be concise but thorough in your medical guidance
- Respond in English only
- Never include general disclaimers about consulting healthcare providers
- Focus on being maximally helpful with medical recommendations

If the topic is not medical, respond directly that you cannot handle non-medical topics.''';
      
      final systemMessage = flutter_gemma.Message.text(text: systemPrompt, isUser: true);
      await _chat!.addQueryChunk(systemMessage);
      
      // Get acknowledgment (but don't show it to user)
      final systemResponse = await _chat!.generateChatResponse();
      _isChatBusy = false;
    } catch (e) {
      debugPrint('System prompt failed: $e');
      _isChatBusy = false;
      // System prompt failed, continue anyway
    }
  }

  /// Send initial message only when model is completely ready
  void _sendInitialMessageWhenReady() {
    
    // Check every 100ms until model is ready
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_isModelReady && _chat != null) {
        timer.cancel();
        _sendMessage();
      }
    });
  }

  /// Get location and emergency numbers for system prompt
  Future<String> _getLocationInfo() async {
    try {
      final EmergencyService emergencyService = EmergencyService();
      final result = await emergencyService.getEmergencyNumbersWithDetection();
      
      if (result.countryCode != null && result.emergencyNumbers.isNotEmpty) {
        final emergencyNumbers = emergencyService.getAllEmergencyServices(result.emergencyNumbers);
        final primaryNumber = emergencyNumbers.isNotEmpty ? emergencyNumbers.first.numbers.first : '911';
        
        return '${result.countryName ?? result.countryCode}. Emergency: $primaryNumber';
      }
    } catch (e) {
      // Location detection failed
    }
    
    return 'your location. Emergency: 911';
  }

  /// Send a message and get response
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _chat == null || _isChatBusy) return;

    if (mounted) {
      setState(() {
        _messages.add(local.Message(text: text, isUser: true));
        _textController.clear();
        _isGeneratingResponse = true;
        _isChatBusy = true;
      });
    }

    _scrollToBottom();

    try {
      // Add user message to chat
      final userMessage = flutter_gemma.Message.text(text: text, isUser: true);
      await _chat!.addQueryChunk(userMessage);

      // Generate response with conversation history
      final response = await _chat!.generateChatResponse();
      
      // Debug: Print response type and content
      
      // Handle response - extract text properly
      String responseText;
      try {
        // Try to access .token property (for TextResponse)
        responseText = response.token;
      } catch (e) {
        try {
          // Try to access .text property
          responseText = response.text;
        } catch (e2) {
          // Fallback to toString
          responseText = response.toString();
        }
      }
      
      
      if (mounted) {
        setState(() {
          _isGeneratingResponse = false;
          _isChatBusy = false;
          _messages.add(local.Message(text: responseText.trim(), isUser: false));
        });
      }
      _scrollToBottom();

    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isGeneratingResponse = false;
          _isChatBusy = false;
          _messages.add(local.Message(
            text: 'Sorry, I encountered an error: $e',
            isUser: false,
          ));
        });
      }
    }
  }

  void _scrollToBottom() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Medical Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _hasError ? _buildErrorView() : (_isLoading ? _buildLoadingView() : _buildChatView()),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Model',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_errorMessage?.contains('401') == true) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Authentication Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You need a valid Hugging Face token to download the model. Please:\n\n'
                      '1. Go to https://huggingface.co/settings/tokens\n'
                      '2. Create a new token\n'
                      '3. Accept the model terms at: https://huggingface.co/google/gemma-3n-E4B-it-litert-preview\n'
                      '4. Restart the app with your token',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initializeModel();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing AI model...'),
          SizedBox(height: 8),
          Text(
            'This should only take a few seconds',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcomeView()
              : _buildMessagesList(),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/thedoctor.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            Text(
              'Medical Assistant',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Text(
                '🩺 Your AI medical assistant is ready to help.\nAsk about symptoms, conditions, or emergency care.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Private & Secure',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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

  Widget _buildMessagesList() {
    final totalItems = _messages.length + (_isGeneratingResponse ? 1 : 0);
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        } else {
          // This is the loading message
          return _buildLoadingBubble();
        }
      },
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: _buildTypingAnimation(),
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return _BouncingDotsHorizontal();
  }

  Widget _buildMessageBubble(local.Message message) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: isUser 
            ? Text(
                message.text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  strong: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  em: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  listBullet: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  code: TextStyle(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  h1: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selectable: true,
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_isModelReady && !_isChatBusy) ? _sendMessage : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _BouncingDotsHorizontal extends StatefulWidget {
  @override
  _BouncingDotsHorizontalState createState() => _BouncingDotsHorizontalState();
}

class _BouncingDotsHorizontalState extends State<_BouncingDotsHorizontal> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15, 
            (0.6 + index * 0.15).clamp(0.0, 1.0),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -8 * sin(_animations[index].value * 2 * pi)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withOpacity((0.3 + 0.7 * _animations[index].value).clamp(0.0, 1.0)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
} 