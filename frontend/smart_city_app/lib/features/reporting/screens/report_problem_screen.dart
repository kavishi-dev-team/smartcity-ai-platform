import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../energy_water/screens/energy_problems_screen.dart';
import '../../energy_water/screens/energy_water_report_screen.dart';
import '../../energy_water/screens/energy_water_statistics_screen.dart';
import '../../energy_water/screens/water_leakage_reports_screen.dart';
import '../../energy_water/screens/water_problems_screen.dart';
import '../../safety/screens/air_quality_screen.dart';
import '../../safety/screens/complaint_history_screen.dart';
import '../../safety/screens/safety_alerts_screen.dart';
import '../../safety/screens/safety_problems_screen.dart';
import '../../traffic/screens/department_information_screen.dart';
import '../../traffic/screens/traffic_incident_map_screen.dart';
import '../../traffic/screens/traffic_problems_screen.dart';
import '../../waste/screens/collection_information_screen.dart';
import '../../waste/screens/recycling_information_screen.dart';
import '../../waste/screens/waste_problems_screen.dart';
import '../../waste/screens/waste_separation_guide_screen.dart';
import '../widgets/issue_location_tracker_card.dart';
import '../widgets/quick_issue_report_sheet.dart';
import 'my_reports_screen.dart';

class ReportProblemScreen extends StatefulWidget {
  final bool embedded;
  final String? initialCategory;

  const ReportProblemScreen({
    super.key,
    this.embedded = false,
    this.initialCategory,
  });

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showQuickReportModal(initialCategory: widget.initialCategory!);
        }
      });
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _showQuickReportModal({String initialCategory = 'waste'}) async {
    await QuickIssueReportSheet.show(
      context,
      initialCategory: initialCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with Quick Report Action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart City Service Hub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Explore Waste, Energy & Water, Traffic, Safety, and Air Quality services or report an issue.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                          ),
                          onPressed: () => _showQuickReportModal(),
                          icon: const Icon(Icons.add_location_alt_rounded),
                          label: const Text('Submit New Issue'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _open(const MyReportsScreen()),
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('View My Reports'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _open(
                            const DomainLocationTrackerScreen(category: 'all'),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Track Locations on Map'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'City Service Dashboards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a domain card below to view live issues, maps, schedules, or submit a report.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),

              // Responsive 5 City Service Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 14.0;
                  final maxW = constraints.maxWidth;
                  final isTwoCol = maxW >= 680;
                  final cardWidth = isTwoCol ? (maxW - spacing) / 2 : maxW;

                  final cards = [
                    // 1. Waste Management Card
                    _serviceHubCard(
                      title: 'Waste Management',
                      subtitle:
                          'Garbage overflow reports, collection schedules, waste separation & recycling guides.',
                      icon: Icons.delete_sweep_rounded,
                      accent: AppColors.waste,
                      badgeText: 'ENVIRONMENTAL',
                      onMainTap: () => _open(const WasteProblemsScreen()),
                      actions: [
                        _HubAction(
                          'Waste Issues',
                          Icons.list_alt_rounded,
                          () => _open(const WasteProblemsScreen()),
                        ),
                        _HubAction(
                          'Collection Schedule',
                          Icons.calendar_month_rounded,
                          () => _open(const CollectionInformationScreen()),
                        ),
                        _HubAction(
                          'Separation Guide',
                          Icons.category_outlined,
                          () => _open(const WasteSeparationGuideScreen()),
                        ),
                        _HubAction(
                          'Recycling Info',
                          Icons.recycling_rounded,
                          () => _open(const RecyclingInformationScreen()),
                        ),
                        _HubAction(
                          '+ Report Waste',
                          Icons.add_circle_outline,
                          () => _showQuickReportModal(initialCategory: 'waste'),
                        ),
                      ],
                    ),

                    // 2. Energy & Water Card
                    _serviceHubCard(
                      title: 'Energy & Water',
                      subtitle:
                          'Power outages, street light faults, water supply issues, leakage maps & utility statistics.',
                      icon: Icons.bolt_rounded,
                      accent: AppColors.energy,
                      badgeText: 'UTILITIES',
                      onMainTap: () =>
                          _open(const EnergyWaterDashboardMenu()),
                      actions: [
                        _HubAction(
                          'Energy Problems',
                          Icons.electrical_services_rounded,
                          () => _open(const EnergyProblemsScreen()),
                        ),
                        _HubAction(
                          'Water Problems',
                          Icons.water_drop_outlined,
                          () => _open(const WaterProblemsScreen()),
                        ),
                        _HubAction(
                          'Leakage Map & Reports',
                          Icons.map_outlined,
                          () => _open(const WaterLeakageReportsScreen()),
                        ),
                        _HubAction(
                          'Utility Statistics',
                          Icons.bar_chart_rounded,
                          () => _open(const EnergyWaterStatisticsScreen()),
                        ),
                        _HubAction(
                          '+ Report Utility Issue',
                          Icons.add_circle_outline,
                          () => _open(const EnergyWaterReportScreen()),
                        ),
                      ],
                    ),

                    // 3. Traffic Management Card
                    _serviceHubCard(
                      title: 'Traffic Management',
                      subtitle:
                          'Road hazards, signal malfunctions, live traffic incident map & responsible departments.',
                      icon: Icons.traffic_rounded,
                      accent: AppColors.primary,
                      badgeText: 'MOBILITY & ROADS',
                      onMainTap: () => _open(const TrafficProblemsScreen()),
                      actions: [
                        _HubAction(
                          'Traffic Problems',
                          Icons.traffic_rounded,
                          () => _open(const TrafficProblemsScreen()),
                        ),
                        _HubAction(
                          'Incident Map',
                          Icons.location_searching_rounded,
                          () => _open(const TrafficIncidentMapScreen()),
                        ),
                        _HubAction(
                          'Departments',
                          Icons.apartment_rounded,
                          () => _open(const DepartmentInformationScreen()),
                        ),
                        _HubAction(
                          '+ Report Traffic',
                          Icons.add_circle_outline,
                          () =>
                              _showQuickReportModal(initialCategory: 'traffic'),
                        ),
                      ],
                    ),

                    // 4. Safety & Complaints Card
                    _serviceHubCard(
                      title: 'Safety & Complaints',
                      subtitle:
                          'Public safety hazards, emergency city alerts, and citizen complaint tracking.',
                      icon: Icons.shield_outlined,
                      accent: AppColors.safety,
                      badgeText: 'PUBLIC SAFETY',
                      onMainTap: () => _open(const SafetyProblemsScreen()),
                      actions: [
                        _HubAction(
                          'Safety Problems',
                          Icons.health_and_safety_outlined,
                          () => _open(const SafetyProblemsScreen()),
                        ),
                        _HubAction(
                          'Safety Alerts',
                          Icons.notifications_active_outlined,
                          () => _open(const SafetyAlertsScreen()),
                        ),
                        _HubAction(
                          'Complaints History',
                          Icons.history_edu_rounded,
                          () => _open(const ComplaintHistoryScreen()),
                        ),
                        _HubAction(
                          '+ Report Safety Issue',
                          Icons.add_circle_outline,
                          () =>
                              _showQuickReportModal(initialCategory: 'safety'),
                        ),
                      ],
                    ),

                    // 5. Air Quality Card
                    _serviceHubCard(
                      title: 'Air Quality Monitoring',
                      subtitle:
                          'Real-time Air Quality Index (AQI), PM2.5/PM10 pollutants, health guidance & 30-day trends.',
                      icon: Icons.air_rounded,
                      accent: AppColors.cyan,
                      badgeText: 'ENVIRONMENT & AQI',
                      onMainTap: () => _open(const AirQualityScreen()),
                      actions: [
                        _HubAction(
                          'Live AQI Monitor',
                          Icons.speed_rounded,
                          () => _open(const AirQualityScreen()),
                        ),
                        _HubAction(
                          'Health & Safety Alerts',
                          Icons.warning_amber_rounded,
                          () => _open(const SafetyAlertsScreen()),
                        ),
                      ],
                    ),
                  ];

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (var i = 0; i < cards.length; i++)
                        SizedBox(
                          width: (isTwoCol && i == cards.length - 1)
                              ? maxW
                              : cardWidth,
                          child: cards[i],
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('City Services & Issue Reporting'),
        actions: [
          IconButton(
            onPressed: () => _showQuickReportModal(),
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Submit New Report',
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _serviceHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required String badgeText,
    required VoidCallback onMainTap,
    required List<_HubAction> actions,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onMainTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            return Padding(
              padding: EdgeInsets.all(isCompact ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 10 : 12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: accent,
                          size: isCompact ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in actions)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          avatar: Icon(action.icon, size: 15, color: accent),
                          label: Text(
                            action.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.border),
                          onPressed: action.onTap,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HubAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HubAction(this.label, this.icon, this.onTap);
}
