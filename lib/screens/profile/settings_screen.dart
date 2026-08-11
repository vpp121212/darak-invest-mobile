import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_properties_store.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notificationsKey = 'darak_notifications_enabled';

  bool _notifications = true;
  int _localItems = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getBool(_notificationsKey) ?? true;
    final localCount = await LocalPropertiesStore.loadLocalProperties();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _localItems = localCount.length;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cardDark,
        content: Text(
          value ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات',
          style: GoogleFonts.cairo(color: textLight),
        ),
      ),
    );
  }

  Future<void> _clearLocalData() async {
    await LocalPropertiesStore.clear();
    if (!mounted) return;
    setState(() => _localItems = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cardDark,
        content: Text(
          'تم مسح البيانات المحلية',
          style: GoogleFonts.cairo(color: textLight),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(
            color: gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'العرض',
            style: GoogleFonts.cairo(
              color: textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeItem(),
          const SizedBox(height: 24),
          Text(
            'الإشعارات',
            style: GoogleFonts.cairo(
              color: textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationsItem(),
          const SizedBox(height: 24),
          Text(
            'البيانات والتخزين',
            style: GoogleFonts.cairo(
              color: textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            Icons.folder_delete_outlined,
            'مسح البيانات المحلية',
            'يحتوي على $_localItems عقاراً محفوظاً على هذا الجهاز',
            _localItems > 0 ? _clearLocalData : null,
          ),
          const SizedBox(height: 24),
          Text(
            'معلومات',
            style: GoogleFonts.cairo(
              color: textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            Icons.gavel,
            'السياسة القانونية',
            'الشروط وسياسة الخصوصية',
            () => context.pushRoute(const LegalRoute()),
          ),
          const SizedBox(height: 24),
          const _AppVersion(),
        ],
      ),
    );
  }

  Widget _buildThemeItem() {
    final mode = ref.watch(themeProvider);
    final label = switch (mode) {
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
      ThemeMode.system => 'تلقائي',
    };
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return _buildMenuItem(
      icon,
      'المظهر',
      'الوضع الحالي: $label',
      () => _showThemePicker(),
    );
  }

  Widget _buildNotificationsItem() {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        value: _notifications,
        onChanged: _toggleNotifications,
        activeThumbColor: Colors.white,
        activeTrackColor: gold,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _notifications
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: gold,
            size: 22,
          ),
        ),
        title: Text(
          'إشعارات التطبيق',
          style: GoogleFonts.cairo(color: textLight, fontSize: 15),
        ),
        subtitle: Text(
          'التنبيهات حول مواعيدك وعروضك',
          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
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
        subtitle: Text(subtitle, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        trailing: onTap == null
            ? null
            : Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showThemePicker() async {
    final controller = ref.read(themeProvider.notifier);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final current = ref.watch(themeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختيار المظهر',
                style: GoogleFonts.cairo(
                  color: textLight,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _themeOption(
                context,
                current,
                ThemeMode.system,
                Icons.brightness_auto_outlined,
                'تلقائي',
                'حسب إضاءة النظام',
              ),
              _themeOption(
                context,
                current,
                ThemeMode.light,
                Icons.light_mode_outlined,
                'فاتح',
                'واجهة فاتحة',
              ),
              _themeOption(
                context,
                current,
                ThemeMode.dark,
                Icons.dark_mode_outlined,
                'داكن',
                'واجهة داكنة',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await controller.setMode(selected);
    }
  }

  Widget _themeOption(
    BuildContext context,
    ThemeMode current,
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = current == mode;
    return ListTile(
      leading: Icon(icon, color: selected ? gold : textMuted, size: 24),
      title: Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
      trailing: selected
          ? Icon(Icons.check_circle, color: gold, size: 22)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 22),
      onTap: () => Navigator.pop(context, mode),
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
