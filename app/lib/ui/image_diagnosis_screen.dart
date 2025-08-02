import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'chat_screen.dart';
import '../services/image_analysis_service.dart';

class ImageDiagnosisScreen extends StatefulWidget {
  const ImageDiagnosisScreen({super.key});

  @override
  State<ImageDiagnosisScreen> createState() => _ImageDiagnosisScreenState();
}

class _ImageDiagnosisScreenState extends State<ImageDiagnosisScreen> {
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _medicalDescription;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      print('📸 IMAGE PICKER: Starting image selection from ${source.name}');
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('📸 IMAGE PICKER: Image selected successfully: ${pickedFile.path}');
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = bytes;
          _medicalDescription = null;
        });
        print('📸 IMAGE PICKER: Image bytes loaded: ${bytes.length}');
      } else {
        print('📸 IMAGE PICKER: No image selected');
      }
    } catch (e) {
      print('📸 IMAGE PICKER: Error selecting image: $e');
      
      String errorMessage = 'Error selecting image: $e';
      
      // Provide more specific error messages
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied: $e\n\nPlease grant camera and photo library permissions in device settings.';
      } else if (e.toString().contains('camera')) {
        errorMessage = 'Camera error: $e\n\nPlease check if the camera is available and not being used by another app.';
      } else if (e.toString().contains('gallery') || e.toString().contains('photo')) {
        errorMessage = 'Gallery error: $e\n\nPlease check if you have photos in your gallery and try again.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _processImage() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔍 IMAGE PROCESSING: Starting image analysis...');
      print('🔍 IMAGE PROCESSING: Image size: ${_selectedImageBytes!.length} bytes');
      
      // Basic validation
      if (_selectedImageBytes!.isEmpty) {
        throw Exception('Image file is empty');
      }
      
      // Analyze with the medical AI model using the bytes directly
      print('🤖 AI ANALYSIS: Starting medical analysis...');
      final String analysis = await ImageAnalysisService.analyzeMedicalImage(_selectedImageBytes!);
      print('🤖 AI ANALYSIS: Analysis completed successfully');
      
      setState(() {
        _medicalDescription = analysis;
        _isProcessing = false;
      });

    } catch (e) {
      print('❌ IMAGE PROCESSING: Error processing image: $e');
      setState(() {
        _isProcessing = false;
      });
      
      String errorMessage = 'Error processing image: $e';
      
      // Provide more specific error messages
      if (e.toString().contains('model')) {
        errorMessage = 'AI model error: $e\n\nPlease make sure the medical model is properly installed and loaded.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error: $e\n\nPlease check your internet connection and try again.';
      } else if (e.toString().contains('memory') || e.toString().contains('out of memory')) {
        errorMessage = 'Memory error: $e\n\nThe image is too large or the device has insufficient memory.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission error: $e\n\nPlease grant camera and photo library permissions in device settings.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat() {
    if (_medicalDescription != null) {
      final formattedMessage = ImageAnalysisService.formatAnalysisForChat(_medicalDescription!);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            initialMessage: formattedMessage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Diagnosis'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection buttons
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected image display
            if (_selectedImageFile != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Selected Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _processImage,
                        icon: _isProcessing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.medical_services),
                        label: Text(_isProcessing ? 'Processing...' : 'Analyze Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Medical description
            if (_medicalDescription != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Medical Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _medicalDescription!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToChat,
                          icon: const Icon(Icons.chat),
                          label: const Text('Discuss with AI Assistant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Analysis suggestions
            if (_selectedImageFile == null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'What can I analyze?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ImageAnalysisService.getAnalysisSuggestions()
                            .map((suggestion) => Chip(
                                  label: Text(
                                    suggestion,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  side: BorderSide(color: Colors.blue[200]!),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Disclaimer
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Medical Disclaimer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This AI analysis is for educational purposes only and should not replace professional medical consultation. Always consult a healthcare professional for accurate diagnosis and treatment.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 