
import 'package:flutter/material.dart';

import '../services/energy_water_service.dart';

class EnergyWaterReportScreen extends StatefulWidget {
  const EnergyWaterReportScreen({super.key});

  @override
  State<EnergyWaterReportScreen> createState() =>
      _EnergyWaterReportScreenState();
}

class _EnergyWaterReportScreenState
    extends State<EnergyWaterReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnergyWaterService _service = EnergyWaterService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _category = 'energy';
  String _priority = 'medium';
  String _subcategory = 'leakage';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      if (_category == 'energy') {
        await _service.createEnergyIssue(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          latitude: latitude,
          longitude: longitude,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
        );
      } else {
        await _service.createWaterIssue(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          subcategory: _subcategory,
          latitude: latitude,
          longitude: longitude,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();

      _titleController.clear();
      _descriptionController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _addressController.clear();
      _cityController.clear();

      setState(() {
        _priority = 'medium';
        _subcategory = 'leakage';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }

          if (keyboardType == const TextInputType.numberWithOptions(
            decimal: true,
          )) {
            if (double.tryParse(value.trim()) == null) {
              return 'Please enter a valid number';
            }
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Report Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'energy',
                    child: Text('Energy Problem'),
                  ),
                  DropdownMenuItem(
                    value: 'water',
                    child: Text('Water Problem'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              if (_category == 'water') ...[
                DropdownButtonFormField<String>(
                  initialValue: _subcategory,
                  decoration: const InputDecoration(
                    labelText: 'Water Problem Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'leakage',
                      child: Text('Water Leakage'),
                    ),
                    DropdownMenuItem(
                      value: 'supply',
                      child: Text('Water Supply Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'quality',
                      child: Text('Water Quality Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _subcategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _titleController,
                label: 'Report Title',
              ),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4,
              ),

              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Low'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('High'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _latitudeController,
                label: 'Latitude',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              _buildTextField(
                controller: _longitudeController,
                label: 'Longitude',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
              ),

              _buildTextField(
                controller: _cityController,
                label: 'City',
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
