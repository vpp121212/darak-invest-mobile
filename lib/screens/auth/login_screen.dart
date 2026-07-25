import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
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
            color: gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withOpacity(0.3)),
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
      decoration: InputDecoration(
        hintText: 'البريد الإلكتروني',
        hintStyle: GoogleFonts.cairo(color: textMuted),
        prefixIcon: const Icon(Icons.email_outlined, color: textMuted),
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold),
        ),
      ),
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
      decoration: InputDecoration(
        hintText: 'كلمة المرور',
        hintStyle: GoogleFonts.cairo(color: textMuted),
        prefixIcon: const Icon(Icons.lock_outline, color: textMuted),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: textMuted,
          ),
        ),
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'كلمة المرور مطلوبة';
        if (val.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
        return null;
      },
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

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? gold.withOpacity(0.5) : gold,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: bgDark, strokeWidth: 2),
                )
              : Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(color: bgDark, fontSize: 17, fontWeight: FontWeight.bold),
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
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text('سجل الآن', style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
