import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AiField extends StatelessWidget {
  final String label;
  final Widget child;

  const AiField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

InputDecoration aiInputDecoration({String? hint, IconData? icon}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 14),
    prefixIcon: icon != null ? Icon(icon, color: textMuted, size: 20) : null,
    filled: true,
    fillColor: bgDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(textMuted.withOpacity(0.15)),
    enabledBorder: border(textMuted.withOpacity(0.15)),
    focusedBorder: border(gold),
    errorBorder: border(Colors.red),
    focusedErrorBorder: border(Colors.red),
  );
}

class AiDropdown extends StatelessWidget {
  final String value;
  final String hint;
  final List<String> items;
  final ValueChanged<String> onSelected;

  const AiDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textMuted.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isNotEmpty ? value : hint,
                style: GoogleFonts.cairo(
                  color: value.isNotEmpty ? textLight : textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: gold),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.cairo(color: textLight)),
                trailing: item == value ? const Icon(Icons.check, color: gold) : null,
                onTap: () {
                  onSelected(item);
                  context.pop();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
