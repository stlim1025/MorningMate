import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/auth_controller.dart';

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
          'Morning Mate',
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
          '아침을 함께하는 당신의 메이트',
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
          label: 'Google로 계속하기',
          icon: Icons.g_mobiledata,
          color: Colors.white,
          textColor: Colors.black87,
          onPressed: _handleGoogleLogin,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 12),

        _buildSocialLoginButton(
          label: '카카오로 계속하기',
          icon: Icons.chat_bubble,
          color: const Color(0xFFFEE500),
          textColor: Colors.black87,
          onPressed: _handleKakaoLogin,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 12),

        _buildSocialLoginButton(
          label: 'Apple로 계속하기',
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
          child: const Text(
            'ID로 로그인',
            style: TextStyle(
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
            'ID 로그인',
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
            label: '이메일',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            colorScheme: colorScheme,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) return '이메일을 입력해주세요';
              if (!value.contains('@')) return '올바른 이메일 형식이 아닙니다';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 비밀번호 필드
          _buildTextField(
            controller: _passwordController,
            label: '비밀번호',
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
              if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
              if (value.length < 6) return '비밀번호는 최소 6자 이상이어야 합니다';
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
                  : const Text(
                      '로그인',
                      style: TextStyle(
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
            child: const Text(
              '계정이 없으신가요? 회원가입',
              style: TextStyle(
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
