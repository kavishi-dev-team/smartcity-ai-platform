import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TermsAndConditionsWidget extends StatelessWidget {
  const TermsAndConditionsWidget({
    super.key,
    required this.accepted,
    required this.onChanged,
    this.errorText,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  void _showTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By creating an account you agree to:\n\n'
            '• Provide accurate information when reporting city problems.\n'
            '• Use the platform only for genuine city-service reports.\n'
            '• Allow the app to use your location and photos only when you '
            'submit a report.\n'
            '• Let city officers contact you about reports you submit.\n\n'
            'Your personal data is used only to provide Smart City services '
            'and is not sold to third parties.\n\n'
            '(Placeholder text - replace with the final terms.)',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: accepted,
              activeColor: AppColors.primary,
              onChanged: (value) => onChanged(value ?? false),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'I accept the ',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  GestureDetector(
                    onTap: () => _showTerms(context),
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}