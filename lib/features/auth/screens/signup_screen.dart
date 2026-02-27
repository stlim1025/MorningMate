import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.secondary.withOpacity(0.3),
              colorScheme.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 뒤로가기 버튼
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: colorScheme.primaryButton),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // 스크롤 가능한 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // 타이틀
                        Text(
                          l10n?.get('signup') ?? 'Sign Up',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: colorScheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.get('introSubtitle') ??
                              'Your mate for the morning',
                          style: TextStyle(
                            color: colorScheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 40),

                        const SizedBox(height: 20),

                        // 이메일 필드
                        _buildTextField(
                          controller: _emailController,
                          label: l10n?.get('emailPlaceholder') ?? 'Email',
                          hint: 'example@email.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          colorScheme: colorScheme,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.get('emailRequired') ??
                                  'Please enter email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return l10n?.get('emailInvalid') ??
                                  'Invalid email format';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 비밀번호 필드
                        _buildTextField(
                          controller: _passwordController,
                          label: l10n?.get('passwordPlaceholder') ?? 'Password',
                          hint: l10n?.get('passwordLengthError') ??
                              'At least 6 characters',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          colorScheme: colorScheme,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colorScheme.textSecondary,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.get('passwordRequired') ??
                                  'Please enter password';
                            }
                            if (value.length < 6) {
                              return l10n?.get('passwordLengthError') ??
                                  'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 비밀번호 확인 필드
                        _buildTextField(
                          controller: _passwordConfirmController,
                          label: l10n?.get('passwordConfirmPlaceholder') ??
                              'Confirm Password',
                          hint: l10n?.get('passwordConfirmHint') ??
                              'Re-enter password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePasswordConfirm,
                          colorScheme: colorScheme,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colorScheme.textSecondary,
                            ),
                            onPressed: () => setState(() =>
                                _obscurePasswordConfirm =
                                    !_obscurePasswordConfirm),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.get('passwordRequired') ??
                                  'Please enter password';
                            }
                            if (value != _passwordController.text) {
                              return l10n?.get('passwordMismatch') ??
                                  'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // 회원가입 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: colorScheme.primaryButton,
                              foregroundColor:
                                  colorScheme.primaryButtonForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    l10n?.get('signup') ?? 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 약관 동의 안내
                        Center(
                          child: Text(
                            l10n?.get('deleteAccountConsent') ??
                                'By signing up, you agree to our Terms of Service and Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppColorScheme colorScheme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: colorScheme.textPrimary),
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.textSecondary),
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.textHint),
          prefixIcon: Icon(icon, color: colorScheme.primaryButton),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await authController.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        context.go('/morning');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
