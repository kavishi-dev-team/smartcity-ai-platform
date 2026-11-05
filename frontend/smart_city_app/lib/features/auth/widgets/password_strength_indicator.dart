import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = Validators.passwordStrength(password);
    final color = score <= 1
        ? AppColors.error
        : score <= 2
            ? AppColors.warning
            : AppColors.success;
    final label = score <= 1
        ? 'Weak'
        : score == 2
            ? 'Fair'
            : score == 3
                ? 'Good'
                : 'Strong';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (index) {
                final filled = index < score;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: filled ? color : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}