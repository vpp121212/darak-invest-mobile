import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// A cinematic scroll-world / diorama showcase of featured properties.
///
/// Full-screen property carousel with a slow ken-burns zoom, blurred
/// cross-fade transitions, an identity header and a floating stats/nav panel.
/// Mirrors the "ScrollWorldLanding" React concept using the app's
/// emerald + royal-gold identity.
@RoutePage()
class ScrollWorldScreen extends StatefulWidget {
  const ScrollWorldScreen({super.key});

  @override
  State<ScrollWorldScreen> createState() => _ScrollWorldScreenState();
}

class _DioramaProperty {
  const _DioramaProperty({
    required this.title,
    required this.neighborhood,
    required this.price,
    required this.space,
    required this.image,
    required this.tag,
  });

  final String title;
  final String neighborhood;
  final String price;
  final String space;
  final String image;
  final String tag;
}

const _dioramaProperties = <_DioramaProperty>[
  _DioramaProperty(
    title: 'فيلا العقيق الفاخرة',
    neighborhood: 'حي العقيق، الرياض',
    price: '1,850,000 ر.س',
    space: '450 م²',
    image:
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1400&q=80',
    tag: 'تجربة ثلاثية الأبعاد سلسة',
  ),
  _DioramaProperty(
    title: 'شقة الياسمين الذكية',
    neighborhood: 'حي الياسمين، الرياض',
    price: '680,000 ر.س',
    space: '180 م²',
    image:
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1400&q=80',
    tag: 'إطلالة بانورامية ذكية',
  ),
  _DioramaProperty(
    title: 'تاون هاوس النرجس',
    neighborhood: 'حي النرجس، الرياض',
    price: '1,250,000 ر.س',
    space: '320 م²',
    image:
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1400&q=80',
    tag: 'تصميم مودرن متكامل',
  ),
];

class _ScrollWorldScreenState extends State<ScrollWorldScreen> {
  int _current = 0;

  _DioramaProperty get _currentProperty => _dioramaProperties[_current];

  void _next() {
    setState(() => _current = (_current + 1) % _dioramaProperties.length);
  }

  void _prev() {
    setState(() =>
        _current = (_current - 1 + _dioramaProperties.length) %
            _dioramaProperties.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _diorama(context)),
          _identityHeader(context),
          _closeButton(context),
        ],
      ),
    );
  }

  Widget _diorama(BuildContext context) {
    final property = _currentProperty;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: Container(
        key: ValueKey(property.title),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _kenBurnsImage(property.image),
            _darkGradientOverlay(),
            _infoPanel(context, property),
          ],
        ),
      ),
    );
  }

  Widget _kenBurnsImage(String url) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.08),
      duration: const Duration(seconds: 24),
      curve: Curves.linear,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColors.gradientA, BrandColors.gradientB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 56),
          ),
        ),
    );
  }

  Widget _darkGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.black38,
            Colors.transparent,
            Colors.black54,
            Colors.black87,
          ],
          stops: [0.0, 0.2, 0.45, 0.75, 1.0],
        ),
      ),
    );
  }

  Widget _identityHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 56,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0C24B), Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.home_rounded, color: Color(0xFF1D1D1F), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دارك وحيك',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'عالم العقارات التفاعلي',
                  style: GoogleFonts.cairo(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 16,
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.close_rounded, color: textLight, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _infoPanel(BuildContext context, _DioramaProperty property) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 40,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          property.neighborhood,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFF5D98B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                property.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.tag,
                  style: GoogleFonts.cairo(color: const Color(0xFFCBD5E1), fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statChip(Icons.maximize, property.space),
                  const SizedBox(width: 12),
                  _statChip(Icons.payments_outlined, property.price, highlighted: true),
                ],
              ),
              const SizedBox(height: 16),
              _navControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted ? AppColors.gold : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: highlighted ? const Color(0xFFF5D98B) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navButton(Icons.arrow_forward_rounded, _prev, 'العقار السابق'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '0${_current + 1} / 0${_dioramaProperties.length}',
              style: GoogleFonts.cairo(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _navButton(Icons.arrow_back_rounded, _next, 'العقار التالي'),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
