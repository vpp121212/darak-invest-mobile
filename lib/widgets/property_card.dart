import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/property.dart';
import '../theme/app_theme.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedNetworkImage(
            imageUrl: property.mainImage,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (c, _) => Container(
              height: 180,
              color: bgDark,
              child: const Center(
                child: CircularProgressIndicator(color: gold, strokeWidth: 2),
              ),
            ),
            errorWidget: (c, _, __) => Container(
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
              color: property.purpose == 'بيع' ? gold : blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              property.purpose,
              style: GoogleFonts.cairo(
                color: property.purpose == 'بيع' ? bgDark : textLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (property.trust >= 80)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: green,
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
    final agent = property.agent;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.title,
            style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: gold),
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
          Row(
            children: [
              _buildSpecItem(Icons.king_bed, '${property.rooms} غرف'),
              const SizedBox(width: 14),
              _buildSpecItem(Icons.bathtub_outlined, '${property.baths} حمام'),
              const SizedBox(width: 14),
              _buildSpecItem(Icons.square_foot, '${property.area} م²'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatPrice(property.price)} ${property.purpose == 'إيجار' ? 'ر.س/شهر' : 'ر.س'}',
                style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (agent != null)
                Flexible(
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
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
