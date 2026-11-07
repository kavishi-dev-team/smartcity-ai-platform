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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      acceptTerms: _acceptedTerms,
    );
    if (!mounted) return;

    if (ok) {
      AppSnackBar.success(context, 'Registration successful. Check your email for the code.');
      Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail, arguments: email);
    } else {
      AppSnackBar.error(context, auth.errorMessage ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Create account',
            subtitle: 'Join the platform to report and follow city problems.',
            icon: Icons.person_add_alt_1,
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
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.fullName,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      hint: '0771234567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      validator: Validators.newPassword,
                      onChanged: (_) => setState(() {}),
                    ),
                    PasswordStrengthIndicator(password: _passwordController.text),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      validator: Validators.confirmPassword(
                        () => _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 12),
                    TermsAndConditionsWidget(
                      accepted: _acceptedTerms,
                      errorText: _termsError ? 'You must accept the Terms & Conditions' : null,
                      onChanged: (value) => setState(() {
                        _acceptedTerms = value;
                        _termsError = false;
                      }),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Create account',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.login),
                          child: const Text('Login'),
                        ),
                      ],
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