import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class EmergencyService {
  static const String _emergencyDataPath = 'assets/data/emergency_numbers_all_countries.json';
  static const Duration _networkTimeout = Duration(seconds: 5);
  
  Map<String, dynamic>? _emergencyData;
  String? _detectedCountryCode;
  
  /// Get the user's country code via IP detection
  Future<String?> detectCountryCode() async {
    try {
      // Try multiple IP detection services for reliability
      final services = [
        'https://ipapi.co/country/',
        'https://api.country.is/',
        'https://ipinfo.io/country',
      ];
      
      for (final serviceUrl in services) {
        try {
          final response = await http.get(
            Uri.parse(serviceUrl),
          ).timeout(_networkTimeout);
          
          if (response.statusCode == 200) {
            String countryCode = response.body.trim().toUpperCase();
            
            // Handle different response formats
            if (serviceUrl.contains('country.is')) {
              final data = json.decode(response.body);
              countryCode = (data['country'] as String).toUpperCase();
            }
            
            // Validate country code format
            if (countryCode.length == 2 && countryCode.isNotEmpty) {
              _detectedCountryCode = countryCode;
              return countryCode;
            }
          }
        } catch (e) {
          // Continue to next service if this one fails
          continue;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Load emergency numbers data from assets
  Future<Map<String, dynamic>> _loadEmergencyData() async {
    if (_emergencyData != null) {
      return _emergencyData!;
    }
    
    try {
      final String jsonString = await rootBundle.loadString(_emergencyDataPath);
      _emergencyData = json.decode(jsonString);
      return _emergencyData!;
    } catch (e) {
      throw Exception('Failed to load emergency numbers data: $e');
    }
  }
  
  /// Get emergency numbers for a specific country
  Future<Map<String, dynamic>?> getEmergencyNumbers(String countryCode) async {
    final data = await _loadEmergencyData();
    final countryData = data[countryCode.toUpperCase()];
    if (countryData == null) return null;
    
    // Return the original structure but with flattened emergency numbers
    return {
      'country_name': countryData['country_name'],
      'country_code': countryData['country_code'],
      'emergency_numbers': _flattenEmergencyNumbers(countryData['emergency_numbers'] ?? {}),
    };
  }
  
  /// Get all available countries sorted alphabetically
  Future<List<CountryInfo>> getAllCountries() async {
    final data = await _loadEmergencyData();
    final countries = <CountryInfo>[];
    
    data.forEach((code, info) {
      if (info is Map<String, dynamic> && info.containsKey('country_name')) {
        // Extract and flatten emergency numbers
        final emergencyNumbers = _flattenEmergencyNumbers(info['emergency_numbers'] ?? {});
        
        countries.add(CountryInfo(
          code: code,
          name: info['country_name'],
          emergencyNumbers: emergencyNumbers,
        ));
      }
    });
    
    // Sort alphabetically by country name
    countries.sort((a, b) => a.name.compareTo(b.name));
    
    return countries;
  }
  
  /// Get emergency numbers with automatic country detection
  Future<EmergencyResult> getEmergencyNumbersWithDetection() async {
    // Try to detect country first
    final detectedCode = await detectCountryCode();
    
    if (detectedCode != null) {
      final numbers = await getEmergencyNumbers(detectedCode);
      if (numbers != null) {
        return EmergencyResult(
          countryCode: detectedCode,
          countryName: numbers['country_name'],
          emergencyNumbers: Map<String, dynamic>.from(numbers['emergency_numbers'] ?? {}),
          wasDetected: true,
        );
      }
    }
    
    // If detection failed, return null to trigger manual selection
    return EmergencyResult(
      countryCode: null,
      countryName: null,
      emergencyNumbers: {},
      wasDetected: false,
    );
  }
  
  /// Flatten the nested emergency numbers structure
  Map<String, dynamic> _flattenEmergencyNumbers(Map<String, dynamic> emergencyNumbers) {
    final flattened = <String, dynamic>{};
    
    emergencyNumbers.forEach((service, data) {
      if (data is Map<String, dynamic> && data.containsKey('All')) {
        final numbers = data['All'];
        if (numbers is List && numbers.isNotEmpty) {
          // Keep all numbers, not just the first one
          flattened[service.toLowerCase()] = numbers.map((n) => n.toString()).toList();
        }
      }
    });
    
    return flattened;
  }

  /// Get the primary emergency number for a country (police/general)
  String? getPrimaryEmergencyNumber(Map<String, dynamic> emergencyNumbers) {
    // Priority order for emergency numbers
    const priority = ['police', 'dispatch', 'fire', 'ambulance', 'medical', 'emergency'];
    
    for (final service in priority) {
      if (emergencyNumbers.containsKey(service)) {
        final numbers = emergencyNumbers[service];
        if (numbers is List && numbers.isNotEmpty) {
          return numbers.first.toString();
        }
      }
    }
    
    // Fallback: return first available number from any service
    if (emergencyNumbers.isNotEmpty) {
      final firstValue = emergencyNumbers.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
    }
    
    return null;
  }

  /// Get all emergency numbers organized by service
  List<EmergencyServiceInfo> getAllEmergencyServices(Map<String, dynamic> emergencyNumbers) {
    final services = <EmergencyServiceInfo>[];
    
    emergencyNumbers.forEach((service, numbers) {
      if (numbers is List && numbers.isNotEmpty) {
        services.add(EmergencyServiceInfo(
          serviceName: service.capitalize(),
          numbers: numbers.map((n) => n.toString()).toList(),
        ));
      }
    });
    
    // Sort by priority
    const priority = ['police', 'dispatch', 'fire', 'ambulance', 'medical', 'emergency'];
    services.sort((a, b) {
      final aIndex = priority.indexOf(a.serviceName.toLowerCase());
      final bIndex = priority.indexOf(b.serviceName.toLowerCase());
      
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      } else if (aIndex != -1) {
        return -1;
      } else if (bIndex != -1) {
        return 1;
      } else {
        return a.serviceName.compareTo(b.serviceName);
      }
    });
    
    return services;
  }
}

class CountryInfo {
  final String code;
  final String name;
  final Map<String, dynamic> emergencyNumbers;
  
  CountryInfo({
    required this.code,
    required this.name,
    required this.emergencyNumbers,
  });
}

class EmergencyServiceInfo {
  final String serviceName;
  final List<String> numbers;
  
  EmergencyServiceInfo({
    required this.serviceName,
    required this.numbers,
  });
}

class EmergencyResult {
  final String? countryCode;
  final String? countryName;
  final Map<String, dynamic> emergencyNumbers;
  final bool wasDetected;
  
  EmergencyResult({
    required this.countryCode,
    required this.countryName,
    required this.emergencyNumbers,
    required this.wasDetected,
  });
}