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
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _confirmedNotRobot = false;

  @override
  void initState() {
    super.initState();
    // If the user opened this screen without an active code in memory
    // (e.g. redirected from login or refreshed), generate one immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if ((auth.verificationCode == null || auth.verificationCode!.isEmpty) &&
          widget.email.isNotEmpty) {
        auth.resendVerification(widget.email);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(widget.email, _codeController.text);
    if (!mounted) return;

    if (ok) {
      AppSnackBar.success(
        context,
        'Human verification complete! Your account is now active — please sign in.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => route.settings.name == AppRoutes.welcome,
      );
    } else {
      AppSnackBar.error(
        context,
        auth.errorMessage ?? 'Invalid or expired security code. Try refreshing.',
      );
    }
  }

  Future<void> _refreshCode() async {
    if (widget.email.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification(widget.email);
    if (!mounted) return;

    if (ok) {
      _codeController.clear();
      setState(() => _confirmedNotRobot = false);
      AppSnackBar.success(context, 'Generated a new security challenge code.');
    } else {
      AppSnackBar.error(
        context,
        auth.errorMessage ?? 'Could not generate a new code.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final activeCode = auth.verificationCode ?? '';
    final typedCode = _codeController.text.trim().toUpperCase();
    final isMatched =
        activeCode.isNotEmpty && typedCode == activeCode.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: 'Confirm Not a Robot',
            subtitle: widget.email.isEmpty
                ? 'Enter the security verification code shown below to complete your registration.'
                : 'Complete the security check below to activate ${widget.email}.',
            icon: Icons.verified_user_rounded,
            badgeText: 'STEP 3 OF 3 • HUMAN SECURITY CHECK',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step Progress Strip (Step 3 Active)
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
                              _CompletedStepChip(label: 'Profile'),
                              Expanded(child: Divider(indent: 8, endIndent: 8)),
                              _CompletedStepChip(label: 'Security'),
                              Expanded(child: Divider(indent: 8, endIndent: 8)),
                              _ActiveStepChip(
                                number: '3',
                                label: 'Human Check',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Security Challenge Code Display Card
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
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Security Verification Code',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        Text(
                                          'Enter this code below to confirm you are human',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Generate New Code',
                                    onPressed: isLoading ? null : _refreshCode,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Stylized Anti-Bot Code Box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.navy,
                                      AppColors.primaryDark,
                                      AppColors.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.skyBlue
                                        .withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'HUMAN VERIFICATION CHALLENGE',
                                      style: TextStyle(
                                        color: AppColors.skyBlue,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (activeCode.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: activeCode
                                            .split('')
                                            .map(
                                              (char) => Container(
                                                width: 34,
                                                height: 42,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.14),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  char,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Interactive "I am not a robot" Checkbox Card
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: activeCode.isEmpty
                                    ? null
                                    : () {
                                        setState(() {
                                          _confirmedNotRobot =
                                              !_confirmedNotRobot;
                                          if (_confirmedNotRobot &&
                                              _codeController.text.isEmpty) {
                                            _codeController.text = activeCode;
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _confirmedNotRobot
                                        ? AppColors.success
                                            .withValues(alpha: 0.08)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _confirmedNotRobot
                                          ? AppColors.success
                                              .withValues(alpha: 0.5)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _confirmedNotRobot,
                                        activeColor: AppColors.success,
                                        onChanged: activeCode.isEmpty
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  _confirmedNotRobot =
                                                      val ?? false;
                                                  if (_confirmedNotRobot &&
                                                      _codeController
                                                          .text.isEmpty) {
                                                    _codeController.text =
                                                        activeCode;
                                                  }
                                                });
                                              },
                                      ),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "I'm not a robot",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            Text(
                                              'Check to auto-fill or type the 8-character code below',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.security_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              AuthTextField(
                                controller: _codeController,
                                label: 'Enter Security Verification Code',
                                hint: activeCode.isNotEmpty
                                    ? 'Type $activeCode'
                                    : 'Enter 8-character code',
                                icon: Icons.pin_outlined,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.done,
                                validator: Validators.code,
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) => _verify(),
                              ),

                              if (typedCode.isNotEmpty &&
                                  activeCode.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      isMatched
                                          ? Icons.check_circle_rounded
                                          : Icons.info_outline_rounded,
                                      size: 16,
                                      color: isMatched
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isMatched
                                          ? 'Security code matched — ready to complete registration'
                                          : 'Keep typing to match the 8-character security code above',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isMatched
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 20),

                              AppButton(
                                label: 'Verify & Complete Registration',
                                isLoading: isLoading,
                                onPressed: _verify,
                              ),

                              const SizedBox(height: 10),

                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (route) =>
                                      route.settings.name == AppRoutes.welcome,
                                ),
                                child: const Text(
                                  'Return to Sign In',
                                  style: TextStyle(color: AppColors.muted),
                                ),
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

class _CompletedStepChip extends StatelessWidget {
  const _CompletedStepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _ActiveStepChip extends StatelessWidget {
  const _ActiveStepChip({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
