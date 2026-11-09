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
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Smart City Terms of Service'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By creating a Smart City AI Platform account, you agree to:\n\n'
            '• Provide accurate location and incident details when reporting urban issues.\n'
            '• Use the platform responsibly for genuine municipal and public-safety reports.\n'
            '• Authorize the platform to process submitted descriptions and photos through Smart City AI triage and routing services.\n'
            '• Allow municipal officers and assigned departments to send status notifications regarding your reports.\n\n'
            'Your personal information is protected under municipal data governance standards and is never shared with third-party advertisers.',
            style: TextStyle(height: 1.45, color: AppColors.text),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accepted
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null
              ? AppColors.error
              : accepted
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
        ),
      ),
      child: Column(
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
                      'I agree to the ',
                      style: TextStyle(color: AppColors.text, fontSize: 13.5),
                    ),
                    GestureDetector(
                      onTap: () => _showTerms(context),
                      child: const Text(
                        'Smart City Terms & Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
