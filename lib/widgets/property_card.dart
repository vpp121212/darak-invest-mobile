import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textMuted.withOpacity(0.1)),
          ),
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            property['image'] ?? '',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              height: 180,
              color: cardDark,
              child: const Icon(Icons.home, size: 50, color: textMuted),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: property['purpose'] == 'بيع' ? gold : const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              property['purpose'] ?? '',
              style: GoogleFonts.cairo(
                color: property['purpose'] == 'بيع' ? bgDark : textLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (property['trusted'] == true)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'موثق',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 10,
          left: 10,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgDark.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : textLight,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property['title'] ?? '',
            style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: gold),
              const SizedBox(width: 4),
              Text(
                '${property['district']}، ${property['city']}',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSpecsRow(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatPrice(property['price'] ?? 0)} ${property['purpose'] == 'إيجار' ? 'ر.س/شهر' : 'ر.س'}',
                style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (property['agent'] != null)
                Text(
                  property['agent'],
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsRow() {
    return Row(
      children: [
        _buildSpecItem(Icons.king_bed, '${property['rooms'] ?? 0} غرف'),
        const SizedBox(width: 14),
        _buildSpecItem(Icons.bathtub_outlined, '${property['baths'] ?? 0} حمام'),
        const SizedBox(width: 14),
        _buildSpecItem(Icons.square_foot, '${property['area'] ?? 0} م²'),
      ],
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
}
