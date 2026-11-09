import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/location/location_service.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/reporting/widgets/interactive_location_picker.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../services/energy_water_service.dart';

class EnergyWaterReportScreen extends StatefulWidget {
  const EnergyWaterReportScreen({super.key});

  @override
  State<EnergyWaterReportScreen> createState() =>
      _EnergyWaterReportScreenState();
}

class _EnergyWaterReportScreenState extends State<EnergyWaterReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnergyWaterService _service = EnergyWaterService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'energy';
  String _priority = 'medium';
  String _subcategory = 'leakage';

  ResolvedLocation _trackedLocation = const ResolvedLocation(
    displayName: 'Kollupitiya, Galle Road, Colombo 03',
    address: 'Kollupitiya, Galle Road',
    city: 'Colombo 3',
    latitude: 6.9022,
    longitude: 79.8530,
  );

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reportedBy = context.read<AuthProvider>().user?.id ?? 1;

      if (_category == 'energy') {
        await _service.createEnergyIssue(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          latitude: _trackedLocation.latitude,
          longitude: _trackedLocation.longitude,
          address: _trackedLocation.address,
          city: _trackedLocation.city,
          reportedBy: reportedBy,
        );
      } else {
        await _service.createWaterIssue(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          subcategory: _subcategory,
          latitude: _trackedLocation.latitude,
          longitude: _trackedLocation.longitude,
          address: _trackedLocation.address,
          city: _trackedLocation.city,
          reportedBy: reportedBy,
        );
      }

      if (!mounted) return;
      context.read<DashboardProvider>().loadCitizenDashboard(userId: reportedBy);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report pinned at ${_trackedLocation.address}, ${_trackedLocation.city} and submitted!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _descriptionController.clear();

      setState(() {
        _priority = 'medium';
        _subcategory = 'leakage';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWater = _category == 'water';
    final quickTemplates = isWater
        ? const [
            (
              'Pipe Leakage',
              'Main water pipeline leakage on roadside',
              'Continuous clean water leaking from a damaged underground pipe onto the road surface.',
              'high',
              'leakage',
            ),
            (
              'Low Pressure / Cut',
              'Unscheduled water supply interruption',
              'Water supply has been cut off and pressure is insufficient for households in this area.',
              'high',
              'supply',
            ),
            (
              'Water Quality',
              'Discolored / turbid tap water reported',
              'Tap water appears cloudy with unusual odor; requires water quality inspection.',
              'critical',
              'quality',
            ),
          ]
        : const [
            (
              'Power Outage',
              'Unscheduled neighborhood power outage',
              'Complete electricity supply interruption affecting residences and street buildings.',
              'high',
              'outage',
            ),
            (
              'Streetlight Fault',
              'Non-functioning municipal streetlight poles',
              'Multiple LED streetlights along the main road remain dark at night.',
              'medium',
              'streetlight',
            ),
            (
              'Transformer Hazard',
              'Sparking overhead power line / transformer fault',
              'Sparks and voltage fluctuations observed near the roadside distribution transformer.',
              'critical',
              'grid',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Energy & Water Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
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
                            isWater
                                ? Icons.water_drop_rounded
                                : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Utility Problem & Location Tracker',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Track exact issue coordinates via map or entered address/town',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. UTILITY DOMAIN & QUICK TEMPLATES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'energy',
                                icon: Icon(Icons.bolt_rounded),
                                label: Text('Energy / Power'),
                              ),
                              ButtonSegment(
                                value: 'water',
                                icon: Icon(Icons.water_drop_outlined),
                                label: Text('Water & Leakage'),
                              ),
                            ],
                            selected: {_category},
                            onSelectionChanged: (s) {
                              setState(() => _category = s.first);
                            },
                          ),
                          if (isWater) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _subcategory,
                              decoration: const InputDecoration(
                                labelText: 'Water Problem Type',
                                prefixIcon: Icon(Icons.water_drop_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'leakage',
                                  child: Text('Water Leakage / Pipe Burst'),
                                ),
                                DropdownMenuItem(
                                  value: 'supply',
                                  child: Text('Water Supply / Low Pressure'),
                                ),
                                DropdownMenuItem(
                                  value: 'quality',
                                  child: Text('Water Quality Problem'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Other Water Issue'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _subcategory = value);
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'Quick-fill common templates:',
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
                            children: quickTemplates.map((tpl) {
                              final active =
                                  _titleController.text.trim() == tpl.$2;
                              return ActionChip(
                                backgroundColor: active
                                    ? AppColors.lightBlue
                                    : AppColors.background,
                                side: BorderSide(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                                label: Text(tpl.$1),
                                onPressed: () {
                                  setState(() {
                                    _titleController.text = tpl.$2;
                                    _descriptionController.text = tpl.$3;
                                    _priority = tpl.$4;
                                    if (isWater) {
                                      _subcategory = tpl.$5;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '2. PROBLEM DESCRIPTION & PRIORITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Report Title',
                              hintText:
                                  'e.g., Main water pipe burst near junction',
                              prefixIcon: Icon(Icons.title_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 3)
                                    ? 'Please enter a report title'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Detailed Description',
                              hintText:
                                  'Describe the utility issue and impact...',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 5)
                                    ? 'Please enter a description'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority / Severity',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low Priority'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium Priority'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High Priority'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Interactive Map & Address/Town Location Tracker
                  InteractiveLocationPicker(
                    initialLocation: _trackedLocation,
                    onLocationChanged: (loc) {
                      _trackedLocation = loc;
                    },
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReport,
                      icon: _isSubmitting
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
                        _isSubmitting
                            ? 'Submitting Report...'
                            : 'Submit Verified Utility Report',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
