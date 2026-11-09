import 'package:flutter/material.dart';
import 'package:smart_city_app/features/reporting/widgets/issue_location_tracker_card.dart';

class WaterLeakageMapScreen extends StatelessWidget {
  const WaterLeakageMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DomainLocationTrackerScreen(
      category: 'water',
      subcategory: 'leakage',
    );
  }
}
