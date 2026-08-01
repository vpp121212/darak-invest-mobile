import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Placeholder for the "add property" flow (step-by-step wizard).
class AddPropertyScreen extends ConsumerWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'إضافة عقار',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_home_work_outlined, color: gold, size: 48),
            ),
            const SizedBox(height: 20),
            Text('سيتم إتاحة إضافة العقار قريباً', style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('يمكنك الآن تصفح العقارات واستخدام الأدوات الذكية', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
