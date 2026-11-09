import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberSession = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final outcome = await auth.login(email, _passwordController.text);
    if (!mounted) return;

    switch (outcome) {
      case LoginOutcome.success:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.homeRouteFor(auth.user!),
          (route) => false,
        );
        break;
      case LoginOutcome.emailNotVerified:
        AppSnackBar.error(
          context,
          auth.errorMessage ?? 'Please verify your email first.',
        );
        Navigator.of(context).pushNamed(
          AppRoutes.verifyEmail,
          arguments: email,
        );
        break;
      case LoginOutcome.failure:
        AppSnackBar.error(
          context,
          auth.errorMessage ?? 'Login failed. Please check your credentials.',
        );
        break;
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Smart City Sign-In Guide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _helpRow(
              Icons.verified_user_outlined,
              'Unified Single Sign-In',
              'No profile selection needed — Citizens, Department Officers, City Managers, and Super Admins all sign in here and are automatically routed to their portal.',
            ),
            const SizedBox(height: 12),
            _helpRow(
              Icons.mark_email_read_outlined,
              'Email Verification',
              'Newly registered citizen accounts receive a 6-digit verification code before first sign-in.',
            ),
            const SizedBox(height: 12),
            _helpRow(
              Icons.lock_reset_rounded,
              'Password Recovery',
              'Use "Forgot password?" to request a secure one-time password reset code.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: 'Sign in to Smart City',
            subtitle:
                'Unified access for Citizens, Department Officers, City Managers & Super Admins.',
            icon: Icons.lock_person_rounded,
            showBack: Navigator.of(context).canPop(),
            trailing: IconButton(
              tooltip: 'Sign-in help',
              onPressed: _showHelp,
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unified Automatic Role Detection Info Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Unified Login — Sign in with your email and password. Citizens, Department Officers, City Managers, and Super Admins are automatically directed to their portal.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Main Credentials Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Account Credentials',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Enter your registered email address and password.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'name@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                                autofillHints: const [AutofillHints.email],
                              ),
                              const SizedBox(height: 14),
                              PasswordField(
                                controller: _passwordController,
                                label: 'Password',
                                validator: Validators.passwordRequired,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberSession,
                                          activeColor: AppColors.primary,
                                          onChanged: (v) => setState(
                                            () => _rememberSession = v ?? true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Keep me signed in',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.forgotPassword),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                label: 'Sign In',
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Security & Platform Capabilities Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Wrap(
                          alignment: WrapAlignment.spaceAround,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _TrustBadge(
                              icon: Icons.shield_outlined,
                              label: 'JWT Secured',
                            ),
                            _TrustBadge(
                              icon: Icons.auto_awesome_outlined,
                              label: 'AI Triage',
                            ),
                            _TrustBadge(
                              icon: Icons.bolt_outlined,
                              label: 'Live Telemetry',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Switch to Register CTA Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New to Smart City Platform?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Create a citizen account in under a minute.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.register),
                              child: const Text('Register'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
