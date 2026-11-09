import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'interactive_location_picker.dart';

class _IssueQuickTemplate {
  final String label;
  final String title;
  final String description;
  final String priority;
  final String? subcategory;

  const _IssueQuickTemplate({
    required this.label,
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.subcategory,
  });
}

class QuickIssueReportSheet {
  QuickIssueReportSheet._();

  static const Map<String, String> _categoryTitles = {
    'waste': 'Report Waste Management Issue',
    'energy': 'Report Energy / Power Issue',
    'water': 'Report Water / Leakage Issue',
    'traffic': 'Report Traffic / Road Issue',
    'safety': 'Report Public Safety Issue',
    'complaint': 'Submit Citizen Complaint',
  };

  static const Map<String, IconData> _categoryIcons = {
    'waste': Icons.delete_sweep_rounded,
    'energy': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'traffic': Icons.traffic_rounded,
    'safety': Icons.shield_outlined,
    'complaint': Icons.rate_review_outlined,
  };

  static const Map<String, List<_IssueQuickTemplate>> _templates = {
    'waste': [
      _IssueQuickTemplate(
        label: 'Overflowing Bin',
        title: 'Overflowing municipal waste bin on street',
        description:
            'The public waste collection bin is overflowing onto the roadside and requires urgent clearance.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Missed Pickup',
        title: 'Missed scheduled household waste collection',
        description:
            'Scheduled municipal garbage collection truck did not arrive for this street zone today.',
        priority: 'medium',
      ),
      _IssueQuickTemplate(
        label: 'Illegal Dumping',
        title: 'Illegal roadside garbage dumping hazard',
        description:
            'Uncollected waste bags and debris have been dumped near the drainage canal causing odor and blockage.',
        priority: 'critical',
      ),
    ],
    'energy': [
      _IssueQuickTemplate(
        label: 'Power Outage',
        title: 'Unscheduled neighborhood power outage',
        description:
            'Complete electricity supply interruption affecting residences and commercial buildings on this street.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Streetlight Fault',
        title: 'Non-functioning municipal streetlight poles',
        description:
            'Multiple LED streetlights along the main road remain dark at night, creating visibility hazards.',
        priority: 'medium',
      ),
      _IssueQuickTemplate(
        label: 'Transformer / Line Hazard',
        title: 'Sparking overhead power line / transformer fault',
        description:
            'Sparks and voltage fluctuations observed near the roadside distribution transformer.',
        priority: 'critical',
      ),
    ],
    'water': [
      _IssueQuickTemplate(
        label: 'Pipe Burst / Leakage',
        title: 'Main water pipeline leakage on roadside',
        description:
            'Continuous clean water leaking from a damaged underground main pipe onto the road surface.',
        priority: 'high',
        subcategory: 'leakage',
      ),
      _IssueQuickTemplate(
        label: 'Supply Interruption',
        title: 'No water supply / severe low pressure',
        description:
            'Water supply has been cut off without prior notice and pressure is insufficient for households.',
        priority: 'high',
        subcategory: 'supply',
      ),
      _IssueQuickTemplate(
        label: 'Water Quality Issue',
        title: 'Discolored / turbid tap water reported',
        description:
            'Tap water appears muddy with unusual odor; requires water quality inspection and flushing.',
        priority: 'critical',
        subcategory: 'quality',
      ),
    ],
    'traffic': [
      _IssueQuickTemplate(
        label: 'Signal Malfunction',
        title: 'Traffic light signal malfunction at junction',
        description:
            'Traffic signal lights are stuck/flashing at the main intersection, causing severe congestion.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Deep Pothole',
        title: 'Dangerous road pothole damaging vehicles',
        description:
            'Large deep pothole in the active traffic lane posing an immediate hazard to two-wheelers and cars.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Road Obstruction',
        title: 'Blocked traffic lane / roadside obstruction',
        description:
            'Fallen barrier or construction debris obstructing normal vehicle flow on the main road.',
        priority: 'critical',
      ),
    ],
    'safety': [
      _IssueQuickTemplate(
        label: 'Fallen Tree / Wire',
        title: 'Fallen tree branch obstructing public walkway',
        description:
            'Large tree limb has fallen across the pedestrian walkway and utility cables after heavy wind.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Open Manhole / Drain',
        title: 'Uncovered storm drain / manhole hazard',
        description:
            'Missing concrete cover on roadside drainage pit posing a severe fall hazard to pedestrians.',
        priority: 'critical',
      ),
      _IssueQuickTemplate(
        label: 'Dark Public Zone',
        title: 'Unsafe unlit pedestrian crossing & bus halt',
        description:
            'Public bus stop and pedestrian crossing lack safety lighting and visibility at night.',
        priority: 'medium',
      ),
    ],
    'complaint': [
      _IssueQuickTemplate(
        label: 'Public Facility Damage',
        title: 'Damaged public walkway & bench infrastructure',
        description:
            'Broken paving slabs and damaged public seating area require municipal maintenance.',
        priority: 'medium',
      ),
      _IssueQuickTemplate(
        label: 'Drainage Blockage',
        title: 'Blocked roadside storm drain causing water stagnation',
        description:
            'Clogged municipal drain causes water pooling and mosquito breeding risk after rain.',
        priority: 'high',
      ),
      _IssueQuickTemplate(
        label: 'Noise / Nuisance',
        title: 'Excessive late-night construction noise disturbance',
        description:
            'Unpermitted heavy machinery noise continuing past municipal quiet hours in residential zone.',
        priority: 'low',
      ),
    ],
  };

  static Future<bool> show(
    BuildContext context, {
    String initialCategory = 'waste',
    String? initialSubcategory,
    ResolvedLocation? initialLocation,
    VoidCallback? onSubmitted,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final photoUrlCtrl = TextEditingController();

    String category = initialCategory;
    String? subcategory =
        initialSubcategory ?? (initialCategory == 'water' ? 'leakage' : null);
    String priority = 'medium';
    bool showPhotoField = false;
    bool submitting = false;

    ResolvedLocation trackedLocation = initialLocation ??
        const ResolvedLocation(
          displayName: 'Kollupitiya, Galle Road, Colombo 03',
          address: 'Kollupitiya, Galle Road',
          city: 'Colombo 3',
          latitude: 6.9022,
          longitude: 79.8530,
        );

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final templates = _templates[category] ?? const <_IssueQuickTemplate>[];

          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Production Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: switch (category) {
                          'waste' => AppColors.wasteGradient,
                          'energy' => AppColors.energyGradient,
                          'water' => AppColors.waterGradient,
                          'safety' => AppColors.safetyGradient,
                          _ => AppColors.brandGradient,
                        },
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _categoryIcons[category] ??
                                  Icons.add_location_alt_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _categoryTitles[category] ??
                                      'Submit New City Report',
                                  style: const TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Live GPS & Town/Address Tracking • AI Priority Triage',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Step 1: Service Category & Subcategory
                    const Text(
                      '1. SERVICE DOMAIN & QUICK TEMPLATES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'City Service Domain',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'waste',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('waste'),
                                  size: 18, color: AppColors.waste),
                              const SizedBox(width: 8),
                              const Text('Waste Management'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'energy',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('energy'),
                                  size: 18, color: AppColors.energy),
                              const SizedBox(width: 8),
                              const Text('Energy & Power Grid'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'water',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('water'),
                                  size: 18, color: AppColors.water),
                              const SizedBox(width: 8),
                              const Text('Water Supply & Leakage'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'traffic',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('traffic'),
                                  size: 18, color: AppColors.traffic),
                              const SizedBox(width: 8),
                              const Text('Traffic & Road Infrastructure'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'safety',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('safety'),
                                  size: 18, color: AppColors.safety),
                              const SizedBox(width: 8),
                              const Text('Public Safety & Hazards'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'complaint',
                          child: Row(
                            children: [
                              Icon(AppColors.categoryIcon('complaint'),
                                  size: 18, color: AppColors.complaint),
                              const SizedBox(width: 8),
                              const Text('General Citizen Complaint'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            category = v;
                            if (v == 'water' && subcategory == null) {
                              subcategory = 'leakage';
                            } else if (v != 'water') {
                              subcategory = null;
                            }
                          });
                        }
                      },
                    ),

                    if (category == 'water') ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: subcategory ?? 'leakage',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Water Issue Type',
                          prefixIcon: Icon(Icons.water_drop_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'leakage',
                            child: Text('Pipe Leakage / Main Burst'),
                          ),
                          DropdownMenuItem(
                            value: 'supply',
                            child:
                                Text('Water Supply Cut / Low Pressure'),
                          ),
                          DropdownMenuItem(
                            value: 'quality',
                            child: Text('Water Quality / Contamination'),
                          ),
                        ],
                        onChanged: (v) =>
                            setModalState(() => subcategory = v),
                      ),
                    ],

                    if (templates.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Quick-fill common issue templates:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: templates.map((tpl) {
                          final active = titleCtrl.text.trim() == tpl.title;
                          return ActionChip(
                            backgroundColor: active
                                ? AppColors.lightBlue
                                : AppColors.background,
                            side: BorderSide(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            avatar: Icon(
                              Icons.bolt_rounded,
                              size: 15,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            label: Text(
                              tpl.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = tpl.title;
                                descCtrl.text = tpl.description;
                                priority = tpl.priority;
                                if (tpl.subcategory != null) {
                                  subcategory = tpl.subcategory;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Step 2: Issue Details & Priority Selector
                    const Text(
                      '2. ISSUE DETAILS & URGENCY LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Problem Title',
                        hintText:
                            'e.g., Main water pipe burst near bus stand',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Enter at least 3 characters'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Description',
                        hintText:
                            'Describe what happened, severity, and any safety impact...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Enter at least 5 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Visual Priority Selector Cards
                    const Text(
                      'Select Urgency / Priority:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _priorityPill(
                          label: 'Low',
                          value: 'low',
                          selected: priority == 'low',
                          color: AppColors.success,
                          onTap: () => setModalState(() => priority = 'low'),
                        ),
                        const SizedBox(width: 8),
                        _priorityPill(
                          label: 'Medium',
                          value: 'medium',
                          selected: priority == 'medium',
                          color: AppColors.primary,
                          onTap: () =>
                              setModalState(() => priority = 'medium'),
                        ),
                        const SizedBox(width: 8),
                        _priorityPill(
                          label: 'High',
                          value: 'high',
                          selected: priority == 'high',
                          color: AppColors.warning,
                          onTap: () => setModalState(() => priority = 'high'),
                        ),
                        const SizedBox(width: 8),
                        _priorityPill(
                          label: 'Critical',
                          value: 'critical',
                          selected: priority == 'critical',
                          color: AppColors.error,
                          onTap: () =>
                              setModalState(() => priority = 'critical'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Step 3: Interactive Location Tracker (Address/Town + Map)
                    const Text(
                      '3. TRACK PROBLEM LOCATION (MAP OR ADDRESS / TOWN)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InteractiveLocationPicker(
                      initialLocation: trackedLocation,
                      onLocationChanged: (loc) {
                        trackedLocation = loc;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Optional Evidence Photo Attachment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setModalState(
                            () => showPhotoField = !showPhotoField,
                          ),
                          icon: Icon(
                            showPhotoField
                                ? Icons.expand_less_rounded
                                : Icons.add_a_photo_outlined,
                            size: 18,
                          ),
                          label: Text(
                            showPhotoField
                                ? 'Hide Evidence Photo Link'
                                : 'Attach Evidence Photo (Optional)',
                          ),
                        ),
                      ],
                    ),
                    if (showPhotoField) ...[
                      TextFormField(
                        controller: photoUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Evidence Photo URL (Optional)',
                          hintText: 'https://example.com/issue-photo.jpg',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    const SizedBox(height: 12),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => submitting = true);
                                try {
                                  final userId =
                                      context.read<AuthProvider>().user?.id;
                                  final res = await http
                                      .post(
                                        Uri.parse(
                                          '${AppConfig.apiBaseUrl}/issues',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'title': titleCtrl.text.trim(),
                                          'description': descCtrl.text.trim(),
                                          'category': category,
                                          'subcategory': subcategory,
                                          'priority': priority,
                                          'reported_by': userId,
                                          'city': trackedLocation.city,
                                          'address': trackedLocation.address,
                                          'latitude': trackedLocation.latitude,
                                          'longitude':
                                              trackedLocation.longitude,
                                          if (photoUrlCtrl.text
                                              .trim()
                                              .isNotEmpty)
                                            'attachment_url':
                                                photoUrlCtrl.text.trim(),
                                        }),
                                      )
                                      .timeout(AppConfig.requestTimeout);

                                  if (res.statusCode != 201 &&
                                      res.statusCode != 200) {
                                    throw Exception(
                                      'Failed (${res.statusCode}): ${res.body}',
                                    );
                                  }

                                  if (context.mounted) {
                                    context
                                        .read<DashboardProvider>()
                                        .loadCitizenDashboard(userId: userId);
                                  }
                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Report pinned at ${trackedLocation.address}, ${trackedLocation.city} and submitted!',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => submitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          submitting
                              ? 'Submitting & Analyzing...'
                              : 'Submit Verified Report',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (created == true && onSubmitted != null) {
      onSubmitted();
    }
    return created == true;
  }

  static Widget _priorityPill({
    required String label,
    required String value,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 16,
                color: selected ? color : AppColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? color : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
