import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/formatters.dart';
import '../models/investment_opportunity.dart';
import '../theme/app_theme.dart';

/// Radar card for a promising neighborhood investment opportunity.
///
/// Visual spec matches the Gulf Investment & Radar HTML component:
/// royal-blue gradient card, light tag, green ROI badge and green->blue progress.
class NeighborhoodRadarCard extends StatelessWidget {
  final InvestmentOpportunity opportunity;
  final VoidCallback onViewDistrict;
  final VoidCallback onInvest;

  const NeighborhoodRadarCard({
    super.key,
    required this.opportunity,
    required this.onViewDistrict,
    required this.onInvest,
  });

  static const _accent = Color(0xFF00E676);
  static const _tagGold = Color(0xFFFFD700);
  static const _progressBlue = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    final opp = opportunity;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tag(opp.tag),
          const SizedBox(height: 12),
          _header(opp),
          const SizedBox(height: 15),
          _fundingBar(opp.fundingPercent, opp.fundingAmount),
          const SizedBox(height: 15),
          _actions(),
        ],
      ),
    );
  }

  Widget _tag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tagGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tagGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights, color: _tagGold, size: 14),
          const SizedBox(width: 4),
          Text(
            tag,
            style: GoogleFonts.cairo(
              color: _tagGold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(InvestmentOpportunity opp) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${opp.district} - ${opp.title}',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opp.subtitle,
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _roiBadge(opp.annualGrowth),
      ],
    );
  }

  Widget _roiBadge(double growth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '+${growth.toStringAsFixed(1)}%',
            style: GoogleFonts.cairo(
              color: _accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'سنوياً',
            style: GoogleFonts.cairo(color: _accent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _fundingBar(double percent, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'مبلغ تغطية الفرصة',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${percent.toStringAsFixed(0)}% (${Formatters.price(amount)})',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (percent.clamp(0, 100) / 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _progressBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'معاينة الحي بالتفصيل',
            filled: false,
            onTap: onViewDistrict,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'استثمر بـ ${Formatters.number(opportunity.minInvestment)} ر.س',
            filled: true,
            onTap: onInvest,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: filled ? 0 : 1),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: filled ? const Color(0xFF1D4ED8) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
