import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _officeNameController = TextEditingController();
  final _crController = TextEditingController();
  bool _obscurePassword = true;
  int _selectedRole = -1;

  static const _roles = [
    {'icon': Icons.visibility_outlined, 'title': 'زائر', 'desc': 'دخول مجاني للتصفح والتجربة', 'value': 'guest'},
    {'icon': Icons.person_outline, 'title': 'متصفح', 'desc': 'تصفح العقارات فقط', 'value': 'browser'},
    {'icon': Icons.campaign_outlined, 'title': 'معلن', 'desc': 'نشر عقارات للبيع/الإيجار', 'value': 'advertiser'},
    {'icon': Icons.handshake_outlined, 'title': 'وسيط', 'desc': 'وسيلة عقارية', 'value': 'agent'},
    {'icon': Icons.business_outlined, 'title': 'مكتب عقار', 'desc': 'إدارة عقارات مكتبية', 'value': 'office'},
  ];

  bool get _isOffice => _selectedRole == 4;
  bool get _needVerification => _selectedRole >= 2;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _officeNameController.dispose();
    _crController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedRole == -1) {
      _snack('اختر نوع الحساب');
      return;
    }
    if (_roles[_selectedRole]['value'] == 'guest') {
      await ref.read(authProvider.notifier).enterAsGuest();
      if (!mounted) return;
      context.router.replaceAll([const AppShellRoute()]);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _normalizePhone(_phoneController.text),
      'password': _passwordController.text,
      'role': _roles[_selectedRole]['value'],
      if (_isOffice) 'officeName': _officeNameController.text.trim(),
      if (_isOffice) 'commercialRegister': _crController.text.trim(),
    };
    final success = await ref.read(authProvider.notifier).register(data);
    if (!mounted) return;
    if (success) {
      if (ref.read(authProvider).isLoggedIn) {
        context.router.replaceAll([const AppShellRoute()]);
      } else {
        _snack('تم إنشاء الحساب، سجّل دخولك الآن');
        context.router.replaceAll([const LoginRoute()]);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }

  /// تطبيع رقم الجوال إلى صيغة يقبلها الخادم:
  /// إزالة الفراغات/الفواصل، تحويل الأرقام العربية إلى لاتينية،
  /// وتحويل `05…` أو `966…` إلى `+966…`.
  String _normalizePhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const latinDigits = '0123456789';
    for (var i = 0; i < arabicDigits.length; i++) {
      p = p.replaceAll(arabicDigits[i], latinDigits[i]);
    }
    if (p.startsWith('+966')) return p;
    if (p.startsWith('966') && p.length > 3) return '+966${p.substring(3)}';
    if (p.startsWith('0') && p.length > 1) return '+966${p.substring(1)}';
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildRolePicker(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 14),
                _buildEmailField(),
                const SizedBox(height: 14),
                _buildPhoneField(),
                const SizedBox(height: 14),
                _buildPasswordField(),
                if (_isOffice) ...[
                  const SizedBox(height: 14),
                  _buildOfficeNameField(),
                  const SizedBox(height: 14),
                  _buildCommercialRegisterField(),
                ],
                if (_needVerification) ...[
                  const SizedBox(height: 14),
                  _buildVerificationNote(),
                ],
                if (auth.error != null) ...[
                  const SizedBox(height: 14),
                  _buildError(auth.error!),
                ],
                const SizedBox(height: 28),
                _buildRegisterButton(auth.isLoading),
                const SizedBox(height: 24),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إنشاء حساب', style: GoogleFonts.cairo(color: gold, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('انضم إلى مجتمع دارك وحيك', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
      ],
    );
  }

  Widget _buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع الحساب', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: _roles.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedRole == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? gold.withValues(alpha: 0.15) : cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? gold : textMuted.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _roles[index]['icon'] as IconData,
                      color: isSelected ? gold : textMuted,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _roles[index]['title'] as String,
                      style: GoogleFonts.cairo(
                        color: isSelected ? gold : textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _roles[index]['desc'] as String,
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('الاسم الكامل', Icons.person_outline),
      validator: (val) => val == null || val.isEmpty ? 'الاسم مطلوب' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
      validator: (val) {
        if (val == null || val.isEmpty) return 'البريد مطلوب';
        if (!val.contains('@')) return 'البريد غير صحيح';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('رقم الجوال (05XXXXXXXX أو 9665XXXXXXXX)', Icons.phone_outlined),
      validator: (val) {
        if (val == null || val.isEmpty) return 'رقم الجوال مطلوب';
        final digits = val.replaceAll(RegExp(r'[\s\-()]'), '');
        if (digits.length < 9) return 'رقم الجوال غير صحيح';
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
          child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textMuted),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'كلمة المرور مطلوبة';
        if (val.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildOfficeNameField() {
    return TextFormField(
      controller: _officeNameController,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('اسم المكتب العقاري', Icons.business_outlined),
      validator: (val) => _isOffice && (val == null || val.isEmpty) ? 'اسم المكتب مطلوب' : null,
    );
  }

  Widget _buildCommercialRegisterField() {
    return TextFormField(
      controller: _crController,
      style: GoogleFonts.cairo(color: textLight),
      decoration: _inputDecoration('رقم السجل التجاري', Icons.numbers),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(color: textMuted),
      prefixIcon: Icon(icon, color: textMuted),
      filled: true,
      fillColor: primarySoft,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: textMuted.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: textMuted.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide:  BorderSide(color: gold)),
    );
  }

  Widget _buildVerificationNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'حسابك سيحتاج إلى توثيق من الإدارة قبل التفعيل',
              style: GoogleFonts.cairo(color: const Color(0xFF60A5FA), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String rawError) {
    final message = _readableError(rawError);
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
              message,
              style: GoogleFonts.cairo(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _readableError(String raw) {
    if (raw.trim().isEmpty) return 'تعذّر إنشاء الحساب، حاول مجدداً';
    if (raw.contains('لا يوجد اتصال') || raw.contains('SocketException')) {
      return 'لا يوجد اتصال بالإنترنت';
    }
    if (raw.contains('مهلة الاتصال') || raw.contains('Timeout')) {
      return 'انتهت مهلة الاتصال، تحقق من اتصالك ثم حاول مجدداً';
    }
    if (raw.contains('تعذّر الاتصال')) {
      return 'تعذّر الاتصال بالخادم، حاول مجدداً';
    }
    // رسائل الخادم تصل بالعربية (تفاصيل التحقق مثل «رقم الجوال غير صحيح»).
    return raw.trim();
  }

  Widget _buildRegisterButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _register,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLoading ? gold.withValues(alpha: 0.5) : gold,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('إنشاء الحساب', style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('لديك حساب بالفعل؟ ', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text('سجّل دخول', style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
