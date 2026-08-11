import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a property image from a local asset (paths starting with
/// `assets/`) or over the network, with caching and graceful fallbacks.
///
/// Bundled demo images load instantly and never disappear on slow/blocked
/// networks, while live API images still stream from the backend.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
  });

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  bool get _isAsset => src.startsWith('assets/');

  Widget _defaultError() {
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: Center(
        child: Icon(Icons.home_rounded, size: 44, color: Color(0xFF64748B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            errorWidget?.call(context, '', Object()) ?? _defaultError(),
      );
    }
    if (src.isEmpty) {
      return errorWidget?.call(context, '', Object()) ?? _defaultError();
    }
    return CachedNetworkImage(
      imageUrl: src,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      placeholder: placeholder,
      errorWidget: errorWidget ?? (_, __, ___) => _defaultError(),
    );
  }
}
