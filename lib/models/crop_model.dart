import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class Crop {
  final int id;
  final double basePrice; // Per kg in INR
  final IconData icon;
  final Color color;
  final double optimalTemp; // Celsius
  final double optimalRain; // mm
  final double optimalHumidity; // %

  Crop({
    required this.id,
    required this.basePrice,
    required this.icon,
    required this.color,
    required this.optimalTemp,
    required this.optimalRain,
    required this.optimalHumidity,
  });

  // Getters that dynamically return the translated value via the Localization Service
  String get name => LocalizationService.translate('crop_${id}_name');
  String get category => LocalizationService.translate('crop_${id}_category');
  String get description => LocalizationService.translate('crop_${id}_desc');
  String get benefits => LocalizationService.translate('crop_${id}_benefits');

  static final List<Crop> allCrops = [
    Crop(
      id: 0,
      basePrice: 25.0,
      icon: Icons.grain,
      color: Colors.amber.shade700,
      optimalTemp: 20.0,
      optimalRain: 100.0,
      optimalHumidity: 60.0,
    ),
    Crop(
      id: 1,
      basePrice: 35.0,
      icon: Icons.grass,
      color: Colors.lightGreen.shade600,
      optimalTemp: 27.0,
      optimalRain: 250.0,
      optimalHumidity: 80.0,
    ),
    Crop(
      id: 2,
      basePrice: 22.0,
      icon: Icons.eco,
      color: Colors.yellow.shade800,
      optimalTemp: 24.0,
      optimalRain: 120.0,
      optimalHumidity: 65.0,
    ),
    Crop(
      id: 3,
      basePrice: 60.0,
      icon: Icons.cloud,
      color: Colors.grey.shade400,
      optimalTemp: 28.0,
      optimalRain: 80.0,
      optimalHumidity: 50.0,
    ),
    Crop(
      id: 4,
      basePrice: 15.0,
      icon: Icons.lens,
      color: Colors.brown.shade400,
      optimalTemp: 18.0,
      optimalRain: 75.0,
      optimalHumidity: 70.0,
    ),
    Crop(
      id: 5,
      basePrice: 30.0,
      icon: Icons.fiber_manual_record,
      color: Colors.red.shade600,
      optimalTemp: 22.0,
      optimalRain: 100.0,
      optimalHumidity: 65.0,
    ),
    Crop(
      id: 6,
      basePrice: 25.0,
      icon: Icons.brightness_high,
      color: Colors.purple.shade300,
      optimalTemp: 20.0,
      optimalRain: 90.0,
      optimalHumidity: 60.0,
    ),
    Crop(
      id: 7,
      basePrice: 4.0,
      icon: Icons.unfold_more,
      color: Colors.green.shade800,
      optimalTemp: 30.0,
      optimalRain: 300.0,
      optimalHumidity: 80.0,
    ),
  ];
}
