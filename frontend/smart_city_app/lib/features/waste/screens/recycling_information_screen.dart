import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

class RecyclingInformationScreen extends StatelessWidget {
  const RecyclingInformationScreen({super.key});

  static const _materials = [
    (
      title: 'Paper & cardboard',
      description:
          'Keep paper clean and dry. Flatten cardboard boxes. '
          'Check local rules for coated or food-soiled packaging.',
      icon: Icons.description_outlined,
    ),
    (
      title: 'Plastic containers',
      description:
          'Empty containers and remove food residue. '
          'Only include plastic types accepted by your collector.',
      icon: Icons.local_drink_outlined,
    ),
    (
      title: 'Glass bottles & jars',
      description:
          'Empty bottles and jars. Check local instructions for lids. '
          'Keep ceramics, mirrors and light bulbs separate.',
      icon: Icons.wine_bar_outlined,
    ),
    (
      title: 'Metal cans',
      description:
          'Empty food tins and drink cans. Remove food residue '
          'and follow local instructions for sharp lids.',
      icon: Icons.kitchen_outlined,
    ),
    (
      title: 'Electronics & batteries',
      description:
          'Use an appropriate authorised collection service. '
          'Keep these items out of ordinary recycling bins.',
      icon: Icons.devices_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recycling information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling, size: 44, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text(
                  'Recycle with care',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Prepare materials before handing them over '
                  'for recycling.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'General guidance only. Accepted materials vary '
                    'by local service. Confirm collection rules '
                    'with your local authority or recycling provider.',
                    style: TextStyle(color: AppColors.text, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                ..._materials.map(
                  (material) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            material.icon,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material.title,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  material.description,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Before collection',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RecyclingTip(
                          text: 'Separate materials by accepted category.',
                        ),
                        _RecyclingTip(text: 'Keep paper and cardboard dry.'),
                        _RecyclingTip(text: 'Remove food and liquid residue.'),
                        _RecyclingTip(
                          text: 'Confirm collection times and drop-off rules.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecyclingTip extends StatelessWidget {
  final String text;

  const _RecyclingTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
