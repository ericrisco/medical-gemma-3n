import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'chat_screen.dart';
import 'country_selector_screen.dart';
import 'first_aid_guide_screen.dart';
import '../services/emergency_service.dart';
import '../data/gemma_downloader_datasource.dart';

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  final GemmaDownloaderDataSource _downloaderDataSource = GemmaDownloaderDataSource();

  Future<void> _makeEmergencyCall(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Detecting your location...'),
          ],
        ),
      ),
    );

    try {
      // Try to get emergency numbers with automatic detection
      final result = await _emergencyService.getEmergencyNumbersWithDetection();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (result.wasDetected && result.countryCode != null) {
          // Successfully detected country
          await _showEmergencyDialog(context, result);
        } else {
          // Detection failed, show country selector
          await _showCountrySelector(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await _showCountrySelector(context);
      }
    }
  }

  Future<void> _showCountrySelector(BuildContext context) async {
    final selectedCountry = await Navigator.of(context).push<CountryInfo>(
      MaterialPageRoute(
        builder: (context) => const CountrySelectorScreen(),
      ),
    );

    if (selectedCountry != null && context.mounted) {
      final result = EmergencyResult(
        countryCode: selectedCountry.code,
        countryName: selectedCountry.name,
        emergencyNumbers: selectedCountry.emergencyNumbers,
        wasDetected: false,
      );
      await _showEmergencyDialog(context, result);
    }
  }

  Future<void> _showEmergencyDialog(BuildContext context, EmergencyResult result) async {
    final services = _emergencyService.getAllEmergencyServices(result.emergencyNumbers);
    
    if (services.isEmpty) {
      // Show error if no emergency numbers available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('No Emergency Numbers'),
            ],
          ),
          content: Text('No emergency numbers found for ${result.countryName ?? result.countryCode}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show emergency call dialog with all numbers
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emergency - ${result.countryName ?? result.countryCode}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!result.wasDetected) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Country manually selected',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      const Text(
                        'Select emergency service to call:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Emergency services
                      ...services.map((service) => _buildEmergencyServiceCard(context, service)),
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap any number to call immediately',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyServiceCard(BuildContext context, EmergencyServiceInfo service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getServiceColor(service.serviceName).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getServiceIcon(service.serviceName),
                  color: _getServiceColor(service.serviceName),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service.serviceName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getServiceColor(service.serviceName),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Numbers
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: service.numbers.map((number) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildNumberButton(context, number),
                )
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _callEmergencyNumber(context, number),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red[300]!.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'police':
        return Colors.blue[700]!;
      case 'fire':
        return Colors.red[700]!;
      case 'ambulance':
      case 'medical':
        return Colors.green[700]!;
      case 'dispatch':
        return Colors.purple[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.local_fire_department;
      case 'ambulance':
      case 'medical':
        return Icons.medical_services;
      case 'dispatch':
        return Icons.support_agent;
      default:
        return Icons.emergency;
    }
  }

  Future<void> _callEmergencyNumber(BuildContext context, String number) async {
    Navigator.of(context).pop(); // Close dialog
    
    // Show confirmation dialog before making emergency call
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Calling emergency services:'),
            const SizedBox(height: 8),
            Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will make an immediate call to emergency services.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
    
    if (shouldCall != true) return;
    
    try {
      // Clean the number (remove any special characters except +)
      final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Try direct calling first
      final result = await FlutterPhoneDirectCaller.callNumber(cleanNumber);
      
      if (result != true && context.mounted) {
        // If direct calling fails, try URL launcher as fallback
        final phoneNumber = 'tel:$cleanNumber';
        if (await canLaunchUrl(Uri.parse(phoneNumber))) {
          await launchUrl(Uri.parse(phoneNumber));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call to $number'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error if something goes wrong
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calling $number: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkModelAvailability() async {
    try {
      final token = dotenv.env['HF_TOKEN'] ?? '';
      if (token.isEmpty) {
        debugPrint('Warning: HF_TOKEN not found in .env file');
        return false;
      }
      final isModelInstalled = await _downloaderDataSource.checkModelExistence(token);
      return isModelInstalled;
    } catch (e) {
      return false;
    }
  }

  Future<void> _openAIAssistant(BuildContext context) async {
    // Check if model is available
    final isModelReady = await _checkModelAvailability();
    
    if (!isModelReady) {
      _showModelNotReadyDialog(context, 'Medical Assistant');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  Future<void> _openFirstAidGuide(BuildContext context) async {
    // Check if model is available
    final isModelReady = await _checkModelAvailability();
    
    if (!isModelReady) {
      _showModelNotReadyDialog(context, 'First Aid Guide');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FirstAidGuideScreen()),
    );
  }

  void _showModelNotReadyDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Not Available'),
        content: const Text(
          'The AI model needs to be downloaded first. Please restart the app and download the model from the setup screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header - Imagen del doctor (ocupa el espacio restante)
              _buildHeader(context),
              
              // Emergency Actions Grid - Tamaño fijo desde abajo
              _buildActionGrid(context),
              
              // Footer
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Image.asset(
          'assets/thedoctor.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si la imagen no carga
            return Container(
              color: Colors.white,
              child: Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.red[600],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tamaños máximos para cada botón
        const double maxEmergencyHeight = 100.0;
        const double maxButtonHeight = 80.0;
        const double spacing = 12.0;
        
        // Calcular si todos los botones caben con el tamaño máximo
        final double totalMaxHeight = maxEmergencyHeight + (maxButtonHeight * 3) + (spacing * 3);
        final bool needsToShrink = totalMaxHeight > constraints.maxHeight;
        
        if (needsToShrink) {
          // Si no caben, usar Expanded para distribuir el espacio
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: _buildEmergencyCallButton(context),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: 'AI Medical Assistant',
                  description: 'Get medical guidance',
                  color: Colors.blue,
                  onTap: () => _openAIAssistant(context),
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.healing,
                  title: 'First Aid Guide',
                  description: 'Step-by-step instructions',
                  color: Colors.orange,
                  onTap: () => _openFirstAidGuide(context),
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.camera_alt,
                  title: 'Image Diagnosis',
                  description: 'Medical assessment from photos',
                  color: Colors.purple,
                  onTap: () => _showComingSoon(context, 'Image Diagnosis'),
                ),
              ),
            ],
          );
        } else {
          // Si caben, usar tamaños fijos máximos
          return Column(
            children: [
              SizedBox(
                height: maxEmergencyHeight,
                child: _buildEmergencyCallButton(context),
              ),
              const SizedBox(height: spacing),
              
              SizedBox(
                height: maxButtonHeight,
                child: _buildActionButton(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: 'AI Medical Assistant',
                  description: 'Get medical guidance',
                  color: Colors.blue,
                  onTap: () => _openAIAssistant(context),
                ),
              ),
              const SizedBox(height: spacing),
              
              SizedBox(
                height: maxButtonHeight,
                child: _buildActionButton(
                  context: context,
                  icon: Icons.healing,
                  title: 'First Aid Guide',
                  description: 'Step-by-step instructions',
                  color: Colors.orange,
                  onTap: () => _openFirstAidGuide(context),
                ),
              ),
              const SizedBox(height: spacing),
              
              SizedBox(
                height: maxButtonHeight,
                child: _buildActionButton(
                  context: context,
                  icon: Icons.camera_alt,
                  title: 'Image Diagnosis',
                  description: 'Medical assessment from photos',
                  color: Colors.purple,
                  onTap: () => _showComingSoon(context, 'Image Diagnosis'),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildEmergencyCallButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[600]!, Colors.red[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red[300]!.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _makeEmergencyCall(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  // Emergency Icon
                  Flexible(
                    flex: 0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.call,
                        size: 28,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text(
                            'CALL EMERGENCY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Immediate emergency assistance',
                            style: TextStyle(
                              color: Colors.red[100],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                children: [
                  // Icon
                  Flexible(
                    flex: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return const SizedBox.shrink();
  }
}