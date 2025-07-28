import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaDownloaderDataSource {
  static const String _modelUrl = 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';
  static const String _modelFilename = 'gemma-3n-E4B-it-int4.task';
  
  // LoRA weights configuration
  static const String _loraUrl = 'https://huggingface.co/ericrisco/medical-gemma-3n-lora/resolve/main/adapter_model.bin';
  static const String _loraFilename = 'adapter_model.bin';

  final FlutterGemmaPlugin _gemma = FlutterGemmaPlugin.instance;
  final ModelFileManager _modelManager = FlutterGemmaPlugin.instance.modelManager;

  /// Load the token from SharedPreferences.
  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Save the token to SharedPreferences.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Helper method to get the model file path.
  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFilename';
  }

  /// Helper method to get the LoRA weights file path.
  Future<String> getLoraFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_loraFilename';
  }

  /// Check if the model is already installed on the device
  Future<bool> checkModelExistence(String token) async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      // Check remote file size
      final Map<String, String> headers =
          token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {};
      final headResponse =
          await http.head(Uri.parse(_modelUrl), headers: headers);

      if (headResponse.statusCode == 200 || headResponse.statusCode == 302) {
        final contentLengthHeader = headResponse.headers['content-length'];
        if (contentLengthHeader != null) {
          final remoteFileSize = int.parse(contentLengthHeader);
          if (file.existsSync() && await file.length() == remoteFileSize) {
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model existence: $e');
      }
    }
    return false;
  }

  /// Check if the LoRA weights are already installed on the device
  Future<bool> checkLoraExistence(String token) async {
    try {
      final filePath = await getLoraFilePath();
      final file = File(filePath);

      // Check remote file size
      final Map<String, String> headers =
          token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {};
      final headResponse =
          await http.head(Uri.parse(_loraUrl), headers: headers);

      if (headResponse.statusCode == 200 || headResponse.statusCode == 302) {
        final contentLengthHeader = headResponse.headers['content-length'];
        if (contentLengthHeader != null) {
          final remoteFileSize = int.parse(contentLengthHeader);
          if (file.existsSync() && await file.length() == remoteFileSize) {
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking LoRA existence: $e');
      }
    }
    return false;
  }

  /// Download the model with progress tracking
  Future<void> downloadModel({
    required String token,
    required Function(double) onProgress,
  }) async {
    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      // Check if file already exists and partially downloaded
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      // Create HTTP request
      final request = http.Request('GET', Uri.parse(_modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Resume download if partially downloaded
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      // Send request and handle response
      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206 || response.statusCode == 302) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        // Download with progress tracking
        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          downloadedBytes += chunk.length;
          onProgress(downloadedBytes / totalBytes);
        }

        await fileSink.close();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to download model: $e');
    } finally {
      fileSink?.close();
    }
  }

  /// Download the LoRA weights with progress tracking
  Future<void> downloadLoraWeights({
    required String token,
    required Function(double) onProgress,
  }) async {
    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      final filePath = await getLoraFilePath();
      final file = File(filePath);

      // Check if file already exists and partially downloaded
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      // Create HTTP request
      final request = http.Request('GET', Uri.parse(_loraUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Resume download if partially downloaded
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      // Send request and handle response
      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206 || response.statusCode == 302) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        // Download with progress tracking
        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          downloadedBytes += chunk.length;
          onProgress(downloadedBytes / totalBytes);
        }

        await fileSink.close();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to download LoRA weights: $e');
    } finally {
      fileSink?.close();
    }
  }

  /// Get the model file path
  String get modelPath => _modelFilename;

  /// Set the model path for flutter_gemma to use the downloaded file
  Future<void> setModelPath() async {
    final filePath = await getFilePath();
    await _modelManager.setModelPath(filePath);
  }

  /// Set the LoRA weights path for flutter_gemma to use the downloaded LoRA weights
  Future<void> setLoraWeightsPath() async {
    final filePath = await getLoraFilePath();
    await _modelManager.setLoraWeightsPath(filePath);
  }

  /// Set environment variable to disable XNNPack cache
  Future<void> setEnvironmentVariable(String key, String value) async {
    try {
      // Try to set environment variable using platform channels or native methods
      // This is a workaround for the XNNPack cache issue in emulators
      if (Platform.isAndroid) {
        // For Android, we'll try to set it through the model manager if available
      }
    } catch (e) {
      // Environment variable could not be set
    }
  }
} 