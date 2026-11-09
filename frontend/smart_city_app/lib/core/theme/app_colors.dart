import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Navy
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color navy = Color(0xFF1E3A8A);

  // High-Tech Telemetry Accents
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color cyan = Color(0xFF06B6D4);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFEFF6FF);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color lightSky = Color(0xFFF0F9FF);
  static const Color card = Color(0xFFFFFFFF);

  // Typography & Borders
  static const Color text = Color(0xFF172554);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFDCEAF7);

  // State Accents
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Smart City Domain Palettes
  static const Color waste = Color(0xFF059669); // Eco Emerald Green
  static const Color wasteLight = Color(0xFFECFDF5);

  static const Color energy = Color(0xFFD97706); // Solar Amber Gold
  static const Color energyLight = Color(0xFFFFFBEB);

  static const Color water = Color(0xFF0284C7); // Aquatic Cyan/Blue
  static const Color waterLight = Color(0xFFF0F9FF);

  static const Color traffic = Color(0xFF2563EB); // Electric Indigo Blue
  static const Color trafficLight = Color(0xFFEFF6FF);

  static const Color safety = Color(0xFFDC2626); // Shield Coral Red
  static const Color safetyLight = Color(0xFFFEF2F2);

  static const Color complaint = Color(0xFF7C3AED); // Civic Purple
  static const Color complaintLight = Color(0xFFF5F3FF);

  static const Color ai = Color(0xFF6366F1); // AI Aurora Violet
  static const Color aiLight = Color(0xFFEEF2FF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, skyBlue],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, skyBlue],
  );

  static const LinearGradient wasteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F46), waste, Color(0xFF34D399)],
  );

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF92400E), energy, Color(0xFFFBBF24)],
  );

  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0369A1), water, Color(0xFF38BDF8)],
  );

  static const LinearGradient trafficGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, traffic, skyBlue],
  );

  static const LinearGradient safetyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF991B1B), safety, Color(0xFFF87171)],
  );

  /// Helper to return matching theme color for any city category
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'waste':
        return waste;
      case 'energy':
        return energy;
      case 'water':
        return water;
      case 'traffic':
        return traffic;
      case 'safety':
        return safety;
      case 'complaint':
        return complaint;
      case 'air_quality':
      case 'aqi':
        return cyan;
      case 'ai':
        return ai;
      default:
        return primary;
    }
  }

  /// Helper to return matching light background for any city category
  static Color categoryBackground(String category) {
    switch (category.toLowerCase()) {
      case 'waste':
        return wasteLight;
      case 'energy':
        return energyLight;
      case 'water':
        return waterLight;
      case 'traffic':
        return trafficLight;
      case 'safety':
        return safetyLight;
      case 'complaint':
        return complaintLight;
      case 'air_quality':
      case 'aqi':
        return lightSky;
      case 'ai':
        return aiLight;
      default:
        return lightBlue;
    }
  }

  /// Helper to return matching standard icon for any city category
  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'waste':
        return Icons.delete_outline_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      case 'water':
        return Icons.water_drop_outlined;
      case 'traffic':
        return Icons.traffic_rounded;
      case 'safety':
        return Icons.shield_outlined;
      case 'complaint':
        return Icons.record_voice_over_outlined;
      case 'air_quality':
      case 'aqi':
        return Icons.air_rounded;
      case 'ai':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
