import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class WasteProblemDetailsScreen extends StatelessWidget {
  final Map<String, String> issue;

  const WasteProblemDetailsScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    const navy = AppColors.text;
    const blue = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waste issue details'),
        backgroundColor: AppColors.card,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['id'] ?? 'Unknown reference',
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  issue['title'] ?? 'Waste issue',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preview • Sample data',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                _detailCard(
                  icon: Icons.info_outline,
                  title: 'Status',
                  value: issue['status'] ?? 'Not available',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: issue['location'] ?? 'Not available',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.description_outlined,
                  title: 'Description',
                  value: _descriptionFor(issue['id']),
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Evidence photos',
                  value: 'No photos attached to this sample issue.',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI analysis summary',
                  value: 'Not available. AI analysis is not connected yet.',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.flag_outlined,
                  title: 'Recommended priority',
                  value: 'Not assessed yet.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(String? id) {
    switch (id) {
      case 'WR-2052':
        return 'Recyclable waste was not collected on the scheduled day.';
      case 'WR-2048':
        return 'A resident has requested collection of bulky household waste.';
      case 'WR-2041':
        return 'A damaged waste bin needs to be replaced.';
      case 'WR-2037':
        return 'A missed household waste collection was reported. '
            'This sample issue is marked as resolved.';
      default:
        return 'No description available.';
    }
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
