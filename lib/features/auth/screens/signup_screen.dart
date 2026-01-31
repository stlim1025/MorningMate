import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/auth_controller.dart';
import '../../../services/user_service.dart';

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
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  String? _nicknameError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
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
                          '회원가입',
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
                          '모닝 메이트와 함께 아침을 시작하세요',
                          style: TextStyle(
                            color: colorScheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 닉네임 필드
                        _buildTextField(
                          controller: _nicknameController,
                          label: '닉네임',
                          hint: '다른 사용자에게 보여질 이름',
                          icon: Icons.person,
                          colorScheme: colorScheme,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return '닉네임을 입력해주세요';
                            if (value.length < 2) return '닉네임은 최소 2자 이상이어야 합니다';
                            if (value.length > 10) return '닉네임은 최대 10자까지 가능합니다';
                            return _nicknameError;
                          },
                          onChanged: (_) {
                            if (_nicknameError != null) {
                              setState(() => _nicknameError = null);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // 이메일 필드
                        _buildTextField(
                          controller: _emailController,
                          label: '이메일',
                          hint: 'example@email.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          colorScheme: colorScheme,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return '이메일을 입력해주세요';
                            if (!value.contains('@') || !value.contains('.'))
                              return '올바른 이메일 형식이 아닙니다';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 비밀번호 필드
                        _buildTextField(
                          controller: _passwordController,
                          label: '비밀번호',
                          hint: '최소 6자 이상',
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
                            if (value == null || value.isEmpty)
                              return '비밀번호를 입력해주세요';
                            if (value.length < 6)
                              return '비밀번호는 최소 6자 이상이어야 합니다';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 비밀번호 확인 필드
                        _buildTextField(
                          controller: _passwordConfirmController,
                          label: '비밀번호 확인',
                          hint: '비밀번호를 다시 입력해주세요',
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
                            if (value == null || value.isEmpty)
                              return '비밀번호 확인을 입력해주세요';
                            if (value != _passwordController.text)
                              return '비밀번호가 일치하지 않습니다';
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
                                : const Text(
                                    '가입하기',
                                    style: TextStyle(
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
                            '가입 시 서비스 이용약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다',
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
    final userService = context.read<UserService>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      // 닉네임 중복 확인
      final nickname = _nicknameController.text.trim();
      final isAvailable = await userService.isNicknameAvailable(nickname);

      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _nicknameError = '이미 사용 중인 닉네임입니다';
            _isLoading = false;
          });
          _formKey.currentState!.validate(); // 에러 메시지 표시를 위해 다시 검증
        }
        return;
      }

      await authController.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        nickname,
      );

      if (mounted) {
        context.go('/morning');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nicknameController.text}님, 환영합니다! 🎉'),
            backgroundColor: colorScheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
