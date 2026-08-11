import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/property.dart';
import '../theme/app_theme.dart';
import 'ken_burns_image.dart';

/// Athletic frosted-glass property card — blurred translucent surface with
/// electric-lime accents, inspired by Nike Training Club.
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  /// Compact layout for horizontal rails (similar properties): shorter image,
  /// tighter padding and no agent row.
  final bool compact;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: glassBorder),
          boxShadow: softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageHeight = compact ? 150.0 : 190.0;
    return Stack(
      children: [
        KenBurnsImage(
          src: property.mainImage,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          memCacheWidth: 700,
          phase: KenBurnsImage.phaseFor(property.title),
          placeholder: (c, _) => Container(
            height: imageHeight,
            color: bgDark,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (c, _, __) => Container(
            height: imageHeight,
            color: primarySoft,
            child:  Icon(Icons.home_rounded, size: 50, color: textMuted),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: property.purpose == 'بيع' ? primary : cyan,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Color(0x66FFD700), blurRadius: 12),
              ],
            ),
            child: Text(
              property.purpose,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (property.trust >= 80 || property.isDemo)
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                if (property.trust >= 80)
                  _buildBadge(
                    icon: Icons.verified,
                    label: 'موثق',
                    color: primary,
                    background: Colors.black.withValues(alpha: 0.55),
                  ),
                if (property.isDemo) ...[
                  if (property.trust >= 80) const SizedBox(width: 6),
                  _buildBadge(
                    icon: Icons.science_outlined,
                    label: 'تجريبي',
                    color: amber,
                    background: scrim.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: gold, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 10),
              ],
            ),
            child: Text(
              '${_formatPrice(property.price)} ر.س${property.purpose == 'إيجار' ? '/شهر' : ''}',
              style: GoogleFonts.cairo(
                color: gold,
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (onFavorite != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(color: glassBorder),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? red : primary,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    final agent = property.agent;
    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.title,
            style: GoogleFonts.cairo(
              color: textLight,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
               Icon(Icons.location_on, size: 16, color: primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.district}، ${property.city}',
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildSpecItem(Icons.king_bed_outlined, '${property.rooms} غرف'),
              _buildSpecItem(Icons.bathtub_outlined, '${property.baths} حمام'),
              _buildSpecItem(
                  Icons.straighten, '${_formatNumber(property.area)} م²'),
            ],
          ),
          const SizedBox(height: 10),
          if (!compact && agent != null) ...[
            Divider(height: 1, color: textMuted.withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration:  BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    agent.name,
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textMuted),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
      ],
    );
  }

  String _formatPrice(num price) {
    return _formatNumber(price);
  }

  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
