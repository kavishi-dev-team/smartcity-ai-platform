import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class WasteSeparationGuideScreen extends StatelessWidget {
  const WasteSeparationGuideScreen({super.key});

  static const _blue = AppColors.primary;
  static const _navy = AppColors.text;
  static const _muted = AppColors.muted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waste separation guide'),
        backgroundColor: AppColors.card,
        foregroundColor: _navy,
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
                const Icon(Icons.recycling, color: _blue, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Separate your waste',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a category to see examples and '
                  'preparation instructions.',
                  style: TextStyle(color: _muted, height: 1.5),
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
                    'General guidance only. Accepted materials and '
                    'bin colours vary by local collection service. '
                    'Follow your local authority’s instructions.',
                    style: TextStyle(color: _navy, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                _categoryCard(
                  icon: Icons.eco_outlined,
                  title: 'Organic waste',
                  subtitle: 'Food scraps and garden materials',
                  examples:
                      'Fruit and vegetable peels, food scraps, '
                      'leaves and small garden trimmings.',
                  preparation:
                      'Keep separate from packaging. '
                      'Check which food and garden materials '
                      'your collection service accepts.',
                  avoid: 'Plastic bags, glass and metal.',
                ),
                _categoryCard(
                  icon: Icons.description_outlined,
                  title: 'Paper & cardboard',
                  subtitle: 'Clean and dry paper products',
                  examples: 'Newspapers, office paper and cardboard boxes.',
                  preparation:
                      'Keep clean and dry. Flatten boxes '
                      'before collection.',
                  avoid:
                      'Food-soiled paper, used tissues and '
                      'coated packaging unless accepted locally.',
                ),
                _categoryCard(
                  icon: Icons.local_drink_outlined,
                  title: 'Plastic',
                  subtitle: 'Accepted bottles and containers',
                  examples:
                      'Plastic bottles and containers accepted '
                      'by your local recycling service.',
                  preparation:
                      'Empty containers and remove food residue. '
                      'Check local rules for lids and plastic types.',
                  avoid:
                      'Do not assume all plastics are recyclable. '
                      'Check separately for bags and wrappers.',
                ),
                _categoryCard(
                  icon: Icons.wine_bar_outlined,
                  title: 'Glass',
                  subtitle: 'Accepted bottles and jars',
                  examples: 'Empty glass bottles and jars.',
                  preparation:
                      'Remove contents and check local '
                      'collection instructions.',
                  avoid:
                      'Ceramics, mirrors, light bulbs and broken '
                      'glass unless your service explicitly accepts them.',
                ),
                _categoryCard(
                  icon: Icons.kitchen_outlined,
                  title: 'Metal',
                  subtitle: 'Accepted cans and containers',
                  examples: 'Empty food tins and drink cans.',
                  preparation:
                      'Empty cans and remove food residue. '
                      'Follow local rules for sharp lids.',
                  avoid:
                      'Batteries, gas cylinders and containers '
                      'with hazardous residue.',
                ),
                _categoryCard(
                  icon: Icons.devices_outlined,
                  title: 'Electronic & special waste',
                  subtitle: 'Items needing separate collection',
                  examples: 'Old electronics, batteries and light bulbs.',
                  preparation:
                      'Use an appropriate authorised '
                      'collection service. Keep these items separate '
                      'from ordinary recycling.',
                  avoid:
                      'Do not dismantle, crush or burn batteries '
                      'or electronic equipment.',
                ),
                _categoryCard(
                  icon: Icons.delete_outline,
                  title: 'General waste',
                  subtitle: 'Remaining accepted household waste',
                  examples:
                      'Non-recyclable household items accepted '
                      'by your collection service.',
                  preparation:
                      'Bag securely and keep separate '
                      'from recyclable and special waste.',
                  avoid: 'Hazardous chemicals, batteries and electronics.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String examples,
    required String preparation,
    required String avoid,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: _blue),
        title: Text(
          title,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _instruction('Examples', examples),
          _instruction('Preparation', preparation),
          _instruction('Keep out', avoid),
        ],
      ),
    );
  }

  Widget _instruction(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: _muted, height: 1.5)),
        ],
      ),
    );
  }
}
