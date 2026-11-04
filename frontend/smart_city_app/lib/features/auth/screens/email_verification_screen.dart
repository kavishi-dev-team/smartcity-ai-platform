import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(widget.email, _codeController.text);
    if (!mounted) return;

    if (ok) {
      AppSnackBar.success(context, 'Email verified. You can log in now.');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => route.settings.name == AppRoutes.welcome,
      );
    } else {
      AppSnackBar.error(context, auth.errorMessage ?? 'Verification failed.');
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification(widget.email);
    if (!mounted) return;

    if (ok) {
      _startCooldown();
      AppSnackBar.success(context, 'A new code has been sent to your email.');
    } else {
      AppSnackBar.error(context, auth.errorMessage ?? 'Could not resend the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      body: Column(
        children: [
          AuthHeader(
            title: 'Verify your email',
            subtitle: widget.email.isEmpty
                ? 'Enter the code we emailed you.'
                : 'We sent a code to ${widget.email}.',
            icon: Icons.mark_email_read_outlined,
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      controller: _codeController,
                      label: 'Verification code',
                      icon: Icons.pin_outlined,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      validator: Validators.code,
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Verify email',
                      isLoading: isLoading,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_secondsLeft > 0 || isLoading) ? null : _resend,
                      child: Text(
                        _secondsLeft > 0
                            ? 'Resend code in ${_secondsLeft}s'
                            : 'Resend code',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => route.settings.name == AppRoutes.welcome,
                      ),
                      child: const Text(
                        'Back to login',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}