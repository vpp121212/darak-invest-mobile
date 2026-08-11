import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Floating frosted-glass pill dock — dark surface with a brand-red
/// active state, Homerch style.
class FloatingDockNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingDockNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['الرئيسية', 'الخريطة', '', 'الرسائل', 'حسابي'];
    const icons = [
      Icons.home_rounded,
      Icons.map_outlined,
      Icons.add_rounded,
      Icons.chat_bubble_outline,
      Icons.person_rounded,
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xF00B3C34),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: glassBorder),
          boxShadow: softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) {
              return _AddButton(onTap: () => onTap(index));
            }
            return Expanded(
              child: _DockItem(
                icon: icons[index],
                label: labels[index],
                active: currentIndex == index,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active ? primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: active ? primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : textMuted,
                size: 20,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: active ? primary : textMuted,
                fontSize: 8,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: brandGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x66FFD700),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
