import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import 'gemma_model_service.dart';
import '../data/gemma_downloader_datasource.dart';

class ImageAnalysisService {

  /// Analyzes an image using the Gemma model for medical diagnosis
  static Future<String> analyzeMedicalImage(Uint8List imageBytes) async {
    // Use the existing model service to get the chat
    final modelService = GemmaModelService();
    
    // Create a chat with image support (like in the example)
    final chat = await modelService.createChat(supportImage: true);
    
    // Create message with image exactly like the example
    const String medicalPrompt = '''Analyze this medical image and provide:
1. What you observe
2. Potential medical conditions
3. Severity assessment 
4. Recommendations''';
    
    // Debug the image bytes
    print('🔍 IMAGE BYTES DEBUG: Length: ${imageBytes.length}');
    print('🔍 IMAGE BYTES DEBUG: First 10 bytes: ${imageBytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    print('🔍 IMAGE BYTES DEBUG: Type: ${imageBytes.runtimeType}');
    
    final userMessage = flutter_gemma.Message.withImage(
      text: 'Give a full description of what you see in the image',
      imageBytes: imageBytes,
      isUser: true,
    );
    
    // Debug the message
    print('🔍 MESSAGE DEBUG: hasImage: ${userMessage.hasImage}');
    print('🔍 MESSAGE DEBUG: imageBytes length in message: ${userMessage.imageBytes?.length}');
    print('🔍 IMAGE ANALYSIS: Sending image with ${imageBytes.length} bytes');
    
    // Add message to chat
    await chat.addQueryChunk(userMessage);
    
    // Generate response (like the example)
    final response = await chat.generateChatResponse();
    
    // Print the response to see what we're getting
    print('🔍 MODEL RESPONSE TYPE: ${response.runtimeType}');
    print('🔍 MODEL RESPONSE CONTENT: $response');
    
    // Handle response - check if it has a token property
    try {
      return (response as dynamic).token ?? response.toString();
    } catch (e) {
      return response.toString();
    }
  }



  /// Creates a formatted message for the chat with the analysis results
  static String formatAnalysisForChat(String analysis) {
    return '''🔬 **Medical Image Analysis Results**

$analysis

---
💬 **Next Steps:**
You can now ask me follow-up questions about this analysis, request additional information about any conditions mentioned, or discuss treatment options. Remember that this analysis is for educational purposes and professional medical consultation is always recommended.''';
  }

  /// Validates if an image is suitable for medical analysis
  static bool isImageSuitableForAnalysis(Uint8List imageBytes) {
    // Basic validation - check if image is not too small
    if (imageBytes.length < 1000) {
      return false; // Image too small
    }
    
    // Check if image is not too large (max 10MB)
    if (imageBytes.length > 10 * 1024 * 1024) {
      return false; // Image too large
    }
    
    return true;
  }

  /// Gets image analysis suggestions based on common medical scenarios
  static List<String> getAnalysisSuggestions() {
    return [
      'Skin conditions and rashes',
      'Wound assessment and healing',
      'Eye and vision problems',
      'Dental and oral health',
      'Musculoskeletal injuries',
      'Respiratory symptoms',
      'Gastrointestinal issues',
      'Neurological symptoms',
      'Cardiovascular concerns',
      'General health screening',
    ];
  }
} 