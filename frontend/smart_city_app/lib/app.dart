import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/energy_water/screens/energy_problems_screen.dart';
import 'features/energy_water/screens/water_problems_screen.dart';
import 'features/energy_water/screens/water_leakage_reports_screen.dart';
import 'features/energy_water/screens/energy_water_statistics_screen.dart';
import 'features/energy_water/screens/energy_water_report_screen.dart';

class SmartCityApp extends StatelessWidget {
  const SmartCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City AI Platform',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AppHomePage(),
    );
  }
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.cyan,
    surface: AppColors.card,
    error: AppColors.error,
  ),

  scaffoldBackgroundColor: AppColors.background,

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.navy,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),

  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 2,
    shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    margin: const EdgeInsets.all(8),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ),
    ),
    labelStyle: const TextStyle(
      color: AppColors.muted,
    ),
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
  ),

  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.text,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.text,
      fontSize: 26,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: AppColors.text,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: AppColors.text,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: AppColors.text,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: AppColors.muted,
      fontSize: 14,
    ),
  ),
);

// Temporary home page to test the theme.
// Replace this with your existing dashboard when ready.
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart City AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_city,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Smart City AI Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Intelligent solutions for a better city.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'City Overview',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Traffic',
                    value: 'Monitoring',
                    icon: Icons.traffic,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: OverviewCard(
                    title: 'Waste',
                    value: 'Management',
                    icon: Icons.delete_outline,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),

            const Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Energy',
                    value: 'Monitoring',
                    icon: Icons.bolt,
                    color: AppColors.warning,
                  ),
                ),
                Expanded(
                  child: OverviewCard(
                    title: 'Water',
                    value: 'Management',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
             width: double.infinity,
             child: ElevatedButton.icon(
             onPressed: () {
            Navigator.push(
             context,
            MaterialPageRoute(
             builder: (context) => const EnergyWaterDashboardMenu(),
        ),
      );
    },
    icon: const Icon(Icons.dashboard),
    label: const Text('Explore Dashboard'),
  ),
),
          ],
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnergyWaterDashboardMenu extends StatelessWidget {
  const EnergyWaterDashboardMenu({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy & Water Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Energy & Water Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a section to explore.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            DashboardMenuCard(
              title: 'Energy Problems',
              subtitle: 'View and manage energy reports',
              icon: Icons.bolt,
              color: AppColors.warning,
              onTap: () => openScreen(
                context,
                const EnergyProblemsScreen(),
              ),
            ),

            DashboardMenuCard(
              title: 'Water Problems',
              subtitle: 'View and manage water reports',
              icon: Icons.water_drop,
              color: AppColors.primary,
              onTap: () => openScreen(
                context,
                const WaterProblemsScreen(),
              ),
            ),

            DashboardMenuCard(
              title: 'Water Leakage Reports',
              subtitle: 'View leakage reports and map',
              icon: Icons.location_on,
              color: AppColors.success,
              onTap: () => openScreen(
                context,
                const WaterLeakageReportsScreen(),
              ),
            ),

            DashboardMenuCard(
              title: 'Energy & Water Statistics',
              subtitle: 'View reports and statistics',
              icon: Icons.bar_chart,
              color: AppColors.cyan,
              onTap: () => openScreen(
                context,
                const EnergyWaterStatisticsScreen(),
              ),
            ),

            DashboardMenuCard(
                title: 'Report a Problem',
                subtitle: 'Submit a new energy or water report',
                icon: Icons.add_circle_outline,
                color: AppColors.primary,
                onTap: () => openScreen(
                context,
            const EnergyWaterReportScreen(),
            ),
           ),
          ],
        ),
      ),
    );
  }
}

class DashboardMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
