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
import '../widgets/password_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/terms_and_conditions_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final ok = await auth.register(
      fullName: _nameController.text,
      email: email,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      acceptTerms: _acceptedTerms,
    );
    if (!mounted) return;

    if (ok) {
      AppSnackBar.success(
        context,
        'Account created! Enter the security code to confirm you are not a robot.',
      );
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.verifyEmail, arguments: email);
    } else {
      AppSnackBar.error(
        context,
        auth.errorMessage ?? 'Registration failed. Please try again.',
      );
    }
  }

  Widget _passwordRuleChip(String label, bool met) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: met
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: met ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.success : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);
    final pwd = _passwordController.text;
    final hasLen = pwd.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasDigit = RegExp(r'\d').hasMatch(pwd);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: 'Create Citizen Account',
            subtitle:
                'Join the Smart City AI Platform to report urban issues and receive real-time alerts.',
            icon: Icons.person_add_alt_1_rounded,
            showBack: Navigator.of(context).canPop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step Progress Strip
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
                          child: const Row(
                            children: [
                              _StepChip(
                                number: '1',
                                label: 'Profile',
                                active: true,
                              ),
                              Expanded(child: Divider(indent: 8, endIndent: 8)),
                              _StepChip(
                                number: '2',
                                label: 'Security',
                                active: true,
                              ),
                              Expanded(child: Divider(indent: 8, endIndent: 8)),
                              _StepChip(
                                number: '3',
                                label: 'Human Check',
                                active: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 1: Personal Details Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Personal & Contact Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'e.g., Kasun Perera',
                                icon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                validator: Validators.fullName,
                                autofillHints: const [AutofillHints.name],
                              ),
                              const SizedBox(height: 14),
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
                              AuthTextField(
                                controller: _phoneController,
                                label: 'Mobile Phone Number',
                                hint: '0771234567 or +94771234567',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: Validators.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                              ),
                              const SizedBox(height: 14),
                              AuthTextField(
                                controller: _addressController,
                                label: 'Residential Address',
                                hint: 'Enter your street address and town/city',
                                icon: Icons.location_on_outlined,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization: TextCapitalization.words,
                                validator: Validators.address,
                                autofillHints: const [
                                  AutofillHints.fullStreetAddress,
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 2: Security & Password Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Account Security',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                controller: _passwordController,
                                label: 'Create Password',
                                validator: Validators.newPassword,
                                onChanged: (_) => setState(() {}),
                              ),
                              PasswordStrengthIndicator(
                                password: _passwordController.text,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _passwordRuleChip('8+ chars', hasLen),
                                  _passwordRuleChip('Uppercase', hasUpper),
                                  _passwordRuleChip('Lowercase', hasLower),
                                  _passwordRuleChip('Number', hasDigit),
                                ],
                              ),
                              const SizedBox(height: 14),
                              PasswordField(
                                controller: _confirmController,
                                label: 'Confirm Password',
                                validator: Validators.confirmPassword(
                                  () => _passwordController.text,
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 16),
                              TermsAndConditionsWidget(
                                accepted: _acceptedTerms,
                                errorText: _termsError
                                    ? 'Please accept the Smart City Terms & Privacy Policy'
                                    : null,
                                onChanged: (value) => setState(() {
                                  _acceptedTerms = value;
                                  _termsError = false;
                                }),
                              ),
                              const SizedBox(height: 18),
                              AppButton(
                                label: 'Create Smart City Account',
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Switch to Login CTA Card
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
                                      'Already have an account?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Sign in to access your dashboard.',
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
                                onPressed: () => Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.login),
                                child: const Text('Sign In'),
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
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final bool active;

  const _StepChip({
    required this.number,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.lightBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.text : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
