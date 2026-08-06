import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(propertiesProvider);

    final agents = <String, AgentInfo>{};
    for (final p in catalogue.properties) {
      final a = p.agent;
      if (a != null) {
        agents.putIfAbsent(a.phone.isEmpty ? a.name : a.phone, () => a);
      }
    }
    final list = agents.values.toList();
    for (var i = 0; i < _demoAgents.length && list.length < 8; i++) {
      list.add(_demoAgents[i]);
    }

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'الوكلاء (${list.length})',
          style: GoogleFonts.cairo(color: primary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تواصل مباشرة مع الوكلاء المعتمدين — اتصال أو واتساب',
                    style: GoogleFonts.cairo(color: textLight, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...list.map((a) => _agentCard(context, a)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static final _demoAgents = [
    AgentInfo(id: 'a1', name: 'م. خالد العتيبي', phone: '+966551234567', email: 'khaled@darak-whayk.sa'),
    AgentInfo(id: 'a2', name: 'أ. نورة القحطاني', phone: '+966552345678', email: 'noura@darak-whayk.sa'),
    AgentInfo(id: 'a3', name: 'م. فهد الدوسري', phone: '+966553456789', email: 'fahad@darak-whayk.sa'),
  ];

  Widget _agentCard(BuildContext context, AgentInfo a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  a.avatar?.isNotEmpty == true ? Icons.person : Icons.person,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.phone,
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                    ),
                    if (a.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        a.email!,
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _action(
                  icon: Icons.call,
                  label: 'اتصال',
                  filled: true,
                  onTap: () => _launch('tel:${a.phone}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _action(
                  icon: Icons.chat,
                  label: 'واتساب',
                  filled: false,
                  onTap: () => _launch('https://wa.me/${a.phone.replaceAll('+', '').replaceAll(' ', '')}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary, width: filled ? 0 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.black : primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: filled ? Colors.black : primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
