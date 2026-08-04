import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'حسابي',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserHeader(context, ref, auth),
          const SizedBox(height: 24),
          Text('أدوات ذكية', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.calculate_outlined, 'تقدير السعر الذكي', 'نموذج AI لتقييم العقار', () {
            context.pushRoute(EstimateRoute());
          }),
          _buildMenuItem(Icons.trending_up, 'حاسبة ROI / التدفق النقدي', 'العائد المتوقع على الاستثمار', () {
            context.pushRoute(RoiRoute());
          }),
          _buildMenuItem(Icons.location_city, 'نبض الحي', 'تحليلات الأحياء والأسعار', () {
            context.pushRoute(PulseRoute());
          }),
          const SizedBox(height: 24),
          Text('عام', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.settings_outlined, 'الإعدادات', null, () {}),
          _buildMenuItem(Icons.help_outline, 'المساعدة والدعم', null, () {}),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 24),
            _buildLogoutButton(ref),
          ],
          const SizedBox(height: 24),
          const _AppVersion(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, WidgetRef ref, AuthState auth) {
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: gold.withValues(alpha: 0.15),
              child: const Icon(Icons.person_outline, color: gold, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سجّل دخولك', style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('استمتع بالعقارات المفضلة والأدوات الذكية', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.pushRoute(const LoginRoute()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('دخول', style: GoogleFonts.cairo(color: bgDark, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    final user = auth.user;
    final name = user?.name.isNotEmpty == true ? user!.name : 'مستخدم';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: gold.withValues(alpha: 0.15),
            child: Text(
              name.characters.first,
              style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (user?.isVerified == true)
            const Icon(Icons.verified, color: green, size: 22),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: gold, size: 22),
        ),
        title: Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 15)),
        subtitle: subtitle == null ? null : Text(subtitle, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(authProvider.notifier).logout(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _AppVersion extends StatelessWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadVersion(),
      builder: (context, snapshot) {
        final version = snapshot.data;
        return Text(
          version == null ? '' : 'دارك وحيك — الإصدار $version',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
        );
      },
    );
  }

  Future<String> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
