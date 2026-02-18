import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/app_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailLogin = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Diary_Background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _showEmailLogin
                  ? _buildEmailLoginForm(colorScheme)
                  : _buildSocialLoginScreen(colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  // 소셜 로그인 화면 (첫 화면)
  Widget _buildSocialLoginScreen(AppColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 캐릭터 아이콘
        Image.asset(
          'assets/icons/Charactor_Icon.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 32),

        Text(
          l10n?.get('introTitle') ?? 'Morning Mate',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontFamily: 'BMJUA',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.get('introSubtitle') ?? 'Your mate for the morning',
          style: TextStyle(
            fontFamily: 'BMJUA',
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // 소셜 로그인 버튼들
        _buildSocialLoginButton(
          label: l10n?.get('loginWithGoogle') ?? 'Continue with Google',
          icon: Icons.g_mobiledata,
          color: Colors.white,
          textColor: Colors.black87,
          onPressed: _handleGoogleLogin,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 12),

        _buildSocialLoginButton(
          label: l10n?.get('loginWithKakao') ?? 'Continue with Kakao',
          icon: Icons.chat_bubble,
          color: const Color(0xFFFEE500),
          textColor: Colors.black87,
          onPressed: _handleKakaoLogin,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 12),

        _buildSocialLoginButton(
          label: l10n?.get('loginWithApple') ?? 'Continue with Apple',
          icon: Icons.apple,
          color: Colors.black,
          textColor: Colors.white,
          onPressed: _handleAppleLogin,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 24),

        // ID로 로그인 버튼
        TextButton(
          onPressed: () {
            setState(() {
              _showEmailLogin = true;
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l10n?.get('loginWithID') ?? 'Login with ID',
            style: const TextStyle(
              fontFamily: 'BMJUA',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 이메일 로그인 폼
  Widget _buildEmailLoginForm(AppColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 뒤로가기 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                setState(() {
                  _showEmailLogin = false;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // 로고
          Image.asset(
            'assets/icons/Charactor_Icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 24),

          Text(
            l10n?.get('idLogin') ?? 'ID Login',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'BMJUA',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 이메일 필드
          _buildTextField(
            controller: _emailController,
            label: l10n?.get('emailPlaceholder') ?? 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            colorScheme: colorScheme,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.get('emailRequired') ?? 'Please enter email';
              }
              if (!value.contains('@')) {
                return l10n?.get('emailInvalid') ?? 'Invalid email format';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 비밀번호 필드
          _buildTextField(
            controller: _passwordController,
            label: l10n?.get('passwordPlaceholder') ?? 'Password',
            icon: Icons.lock,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            colorScheme: colorScheme,
            onSubmitted: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: colorScheme.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.get('passwordRequired') ?? 'Please enter password';
              }
              if (value.length < 6) {
                return l10n?.get('passwordLengthError') ??
                    'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // 로그인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: colorScheme.primaryButton,
                foregroundColor: colorScheme.primaryButtonForeground,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n?.get('login') ?? 'Login',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // 회원가입 버튼
          TextButton(
            onPressed: () => context.push('/signup'),
            child: Text(
              l10n?.get('noAccountSignup') ?? "Don't have an account? Sign Up",
              style: const TextStyle(
                fontFamily: 'BMJUA',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColorScheme colorScheme,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        style: TextStyle(color: colorScheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.textSecondary),
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
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    required AppColorScheme colorScheme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: textColor, size: 28),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'BMJUA',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color == Colors.white
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await authController.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        final user = authController.userModel;
        if (user?.suspendedUntil != null &&
            user!.suspendedUntil!.isAfter(DateTime.now())) {
          await _showSuspensionDialog(context, user);
          return;
        }
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

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await authController.signInWithGoogle();

      if (mounted) {
        final user = authController.userModel;
        if (user?.suspendedUntil != null &&
            user!.suspendedUntil!.isAfter(DateTime.now())) {
          await _showSuspensionDialog(context, user);
          return;
        }
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

  Future<void> _handleKakaoLogin() async {
    setState(() {
      _isLoading = true;
    });

    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await authController.signInWithKakao();

      if (mounted) {
        final user = authController.userModel;
        if (user?.suspendedUntil != null &&
            user!.suspendedUntil!.isAfter(DateTime.now())) {
          await _showSuspensionDialog(context, user);
          return;
        }
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

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await authController.signInWithApple();

      if (mounted) {
        final user = authController.userModel;
        if (user?.suspendedUntil != null &&
            user!.suspendedUntil!.isAfter(DateTime.now())) {
          await _showSuspensionDialog(context, user);
          return;
        }
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

  Future<void> _showSuspensionDialog(
      BuildContext context, UserModel user) async {
    String remainingTime = '';
    final suspendedUntil = user.suspendedUntil!;
    final now = DateTime.now();
    final diff = suspendedUntil.difference(now);

    final l10n = AppLocalizations.of(context);
    if (suspendedUntil.year >= 2090) {
      remainingTime = l10n?.get('permanentSuspension') ?? '영구 정지';
    } else if (diff.inDays > 0) {
      remainingTime = l10n?.getFormat('daysRemaining', {
            'days': diff.inDays.toString(),
            'hours': (diff.inHours % 24).toString(),
          }) ??
          '${diff.inDays}일 ${diff.inHours % 24}시간 남음';
    } else if (diff.inHours > 0) {
      remainingTime = l10n?.getFormat('hoursRemaining', {
            'hours': diff.inHours.toString(),
            'minutes': (diff.inMinutes % 60).toString(),
          }) ??
          '${diff.inHours}시간 ${diff.inMinutes % 60}분 남음';
    } else {
      remainingTime = l10n?.getFormat('minutesRemaining', {
            'minutes': diff.inMinutes.toString(),
          }) ??
          '${diff.inMinutes}분 남음';
    }

    await AppDialog.show(
      context: context,
      key: AppDialogKey.suspension,
      barrierDismissible: false,
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n?.get('suspensionContent') ??
                  '커뮤니티 가이드라인 위반으로 인해\n서비스 이용이 일시적으로 제한되었습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'BMJUA',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Option_Area.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n?.get('remainingTimeTitle') ?? '해제까지 남은 시간',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingTime,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                ],
              ),
            ),
            if (user.suspensionReason != null) ...[
              const SizedBox(height: 16),
              Builder(builder: (context) {
                String reasonStr = user.suspensionReason!;
                if (reasonStr == '커뮤니티 가이드라인 위반') {
                  reasonStr =
                      l10n?.get('reason_community_violation') ?? reasonStr;
                }
                return Text(
                  l10n?.getFormat('suspensionReason', {'reason': reasonStr}) ??
                      '사유: $reasonStr',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    fontFamily: 'BMJUA',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: l10n?.get('logout') ?? '로그아웃',
          isPrimary: true,
          onPressed: (BuildContext dialogContext) async {
            final auth = dialogContext.read<AuthController>();
            Navigator.pop(dialogContext);
            await auth.signOut();
          },
        ),
      ],
    );
  }
}
