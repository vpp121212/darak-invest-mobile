import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      context.router.replaceAll([const AppShellRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildTitle(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildForgotPassword(),
                if (auth.error != null) ...[
                  const SizedBox(height: 8),
                  _buildError(auth.error!),
                ],
                const SizedBox(height: 24),
                _buildLoginButton(auth.isLoading),
                const SizedBox(height: 24),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.home_work_outlined, size: 40, color: gold),
        ),
        const SizedBox(height: 16),
        Text(
          'دارك وحيك',
          style: GoogleFonts.cairo(color: gold, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text('مرحباً بعودتك', style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('سجّل دخولك للوصول إلى حسابك', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
      validator: (val) {
        if (val == null || val.isEmpty) return 'البريد الإلكتروني مطلوب';
        if (!val.contains('@')) return 'البريد الإلكتروني غير صحيح';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('كلمة المرور', Icons.lock_outline).copyWith(
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: textMuted,
          ),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'كلمة المرور مطلوبة';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(color: textMuted),
      prefixIcon: Icon(icon, color: textMuted),
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {},
        child: Text('نسيت كلمة المرور؟', style: GoogleFonts.cairo(color: gold, fontSize: 13)),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _readableError(error),
              style: GoogleFonts.cairo(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _readableError(String raw) {
    if (raw.contains('401') || raw.contains('Invalid') || raw.contains('invalid')) {
      return 'البريد أو كلمة المرور غير صحيحة';
    }
    if (raw.contains('timeout') || raw.contains('Timeout')) {
      return 'انتهت مهلة الاتصال، تحقق من اتصالك بالإنترنت';
    }
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return 'تعذّر الاتصال بالخادم، حاول مجدداً';
    }
    return 'تعذّر تسجيل الدخول، حاول مجدداً';
  }

  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _login,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLoading ? gold.withValues(alpha: 0.5) : gold,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('ليس لديك حساب؟ ', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
        GestureDetector(
          onTap: () => context.pushRoute(const RegisterRoute()),
          child: Text('سجل الآن', style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
