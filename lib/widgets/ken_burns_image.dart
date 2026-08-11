import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_image.dart';

/// Wraps [AppImage] with a slow cinematic Ken Burns zoom loop, mirroring the
/// motion of the property reel so cards feel alive without any network cost.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
    this.duration = const Duration(seconds: 10),
    this.minScale = 1.0,
    this.maxScale = 1.18,
  });

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _scale,
        child: AppImage(
          src: widget.src,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          memCacheWidth: widget.memCacheWidth,
          placeholder: widget.placeholder,
          errorWidget: widget.errorWidget,
        ),
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
