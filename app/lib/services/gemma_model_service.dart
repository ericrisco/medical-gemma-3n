import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import 'package:flutter_gemma/core/model.dart';
import '../data/gemma_downloader_datasource.dart';

/// Singleton service to manage the Gemma model globally
/// This ensures we only have one model instance throughout the app
class GemmaModelService {
  static final GemmaModelService _instance = GemmaModelService._internal();
  factory GemmaModelService() => _instance;
  GemmaModelService._internal();

  final GemmaDownloaderDataSource _downloaderDataSource = GemmaDownloaderDataSource();
  
  dynamic _inferenceModel;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if model is initialized and ready to use
  bool get isReady => _isInitialized && _inferenceModel != null;

  /// Get the model instance (initialize if needed)
  Future<dynamic> getModel() async {
    if (isReady) {
      print('🔄 GEMMA SERVICE: Model already ready, returning existing instance');
      return _inferenceModel;
    }

    if (_isInitializing) {
      print('⏳ GEMMA SERVICE: Model is initializing, waiting...');
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _inferenceModel;
    }

    return await _initializeModel();
  }

  /// Initialize the model (only called once)
  Future<dynamic> _initializeModel() async {
    if (isReady) return _inferenceModel;

    _isInitializing = true;
    print('🚀 GEMMA SERVICE: Initializing model for the first time...');

    try {
      // Set the model path
      print('📁 GEMMA SERVICE: Setting model path...');
      await _downloaderDataSource.setModelPath();

      // Create the model instance
      print('🤖 GEMMA SERVICE: Creating Gemma model...');
      final gemma = FlutterGemmaPlugin.instance;
      
      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: true,
        maxTokens: 2048,
      );

      _isInitialized = true;
      _isInitializing = false;
      
      print('✅ GEMMA SERVICE: Model initialized successfully');
      return _inferenceModel;
      
    } catch (e) {
      _isInitializing = false;
      print('💥 GEMMA SERVICE: Model initialization failed: $e');
      throw Exception('Failed to initialize Gemma model: $e');
    }
  }

  /// Create a new session for one-time inference
  Future<dynamic> createSession({
    double temperature = 0.7,
    int randomSeed = 1,
    int topK = 40,
    bool enableVisionModality = false,
  }) async {
    final model = await getModel();
    print('📝 GEMMA SERVICE: Creating new session...');
    
    final session = await model.createSession(
      enableVisionModality: enableVisionModality, // Enable image processing if requested
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );
    
    print('✅ GEMMA SERVICE: Session created successfully');
    return session;
  }

  /// Create a new chat for conversation with history
  Future<dynamic> createChat({
    bool supportImage = false,
  }) async {
    final model = await getModel();
    print('💬 GEMMA SERVICE: Creating new chat...');
    
    final chat = await model.createChat(
      supportImage: supportImage
    );
    
    print('✅ GEMMA SERVICE: Chat created successfully');
    return chat;
  }

  /// Dispose of the model (should only be called when app is closing)
  Future<void> dispose() async {
    if (_inferenceModel != null) {
      print('🧹 GEMMA SERVICE: Disposing model...');
      await _inferenceModel!.close();
      _inferenceModel = null;
      _isInitialized = false;
      print('✅ GEMMA SERVICE: Model disposed');
    }
  }
}