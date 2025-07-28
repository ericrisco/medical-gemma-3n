import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart' as flutter_gemma;
import 'package:flutter_gemma/core/model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/gemma_downloader_datasource.dart';
import 'dashboard_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final GemmaDownloaderDataSource _downloaderDataSource = GemmaDownloaderDataSource();
  
  bool _isChecking = true;
  bool _isModelReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  /// Check if the model is already downloaded
  Future<void> _checkModelStatus() async {
    setState(() {
      _isChecking = true;
      _hasError = false;
    });

    try {
      final token = dotenv.env['HF_TOKEN'] ?? '';
      if (token.isEmpty) {
        throw Exception('HF_TOKEN not found in .env file');
      }
      await _downloaderDataSource.saveToken(token);
      
      final isModelInstalled = await _downloaderDataSource.checkModelExistence(token);
      
      setState(() {
        _isModelReady = isModelInstalled;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// Download the AI model
  Future<void> _downloadModel() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _downloadProgress = 0.0;
    });

    try {
      final token = dotenv.env['HF_TOKEN'] ?? '';
      if (token.isEmpty) {
        throw Exception('HF_TOKEN not found in .env file');
      }
      
      // Download the model
      await _downloaderDataSource.downloadModel(
        token: token,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      // Set the model path
      await _downloaderDataSource.setModelPath();

      setState(() {
        _isDownloading = false;
        _isModelReady = true;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// Navigate to dashboard screen
  void _proceedToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: _buildContent(),
              ),
              if (_isModelReady) _buildProceedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    Widget content;
    if (_isChecking) {
      content = _buildCheckingView();
    } else if (_hasError) {
      content = _buildErrorView();
    } else if (_isModelReady) {
      content = _buildReadyView();
    } else if (_isDownloading) {
      content = _buildDownloadingView();
    } else {
      content = _buildSetupView();
    }
    
    return SingleChildScrollView(
      child: content,
    );
  }

  Widget _buildCheckingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking AI model status...'),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        
        // Doctor Image
        Container(
          width: 200,
          height: 200,
          child: Image.asset(
            'assets/thedoctor.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.medical_services,
                  size: 100,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Offline AI Explanation
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'This app works completely offline, making it perfect for emergencies when '
                'phone lines are down or internet is unavailable. Once downloaded, you can '
                'get medical guidance even in remote areas, during natural disasters, or when '
                'networks are overloaded.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Download Information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'One-time download required',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Model size: ~4GB • Download time: 5-15 minutes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Internet connection required only for initial download',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Download Button or Progress
        if (!_isDownloading) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadModel,
              icon: const Icon(Icons.download),
              label: const Text('Download AI Model'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Doctor Image
        Container(
          width: 200,
          height: 200,
          child: Image.asset(
            'assets/thedoctor.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.medical_services,
                  size: 100,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        
        // Download Progress
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading AI Model...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Please keep the app open and connected to the internet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.check,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          'Emergency Assistant Ready!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.emergency,
                size: 32,
                color: Colors.green[600],
              ),
              const SizedBox(height: 12),
              Text(
                'Ready for emergency situations!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can now disconnect from the internet. Your medical assistant will work '
                'even when phone lines are down, during natural disasters, or in remote areas '
                'with no network coverage.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Features List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFeatureItem(Icons.emergency, 'Emergency Ready'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.signal_wifi_off, 'No Internet Required'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.phone_disabled, 'Works When Lines Are Down'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.medical_services, 'Medical Guidance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red[400],
        ),
        const SizedBox(height: 24),
        Text(
          'Download Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            children: [
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _checkModelStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.download),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _proceedToDashboard,
        icon: const Icon(Icons.dashboard),
        label: const Text('Open Emergency Dashboard'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}