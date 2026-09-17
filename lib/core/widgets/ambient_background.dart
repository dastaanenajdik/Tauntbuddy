import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A deliberately quiet page canvas.
///
/// Earlier builds animated three large translucent blooms and painted a grid on
/// every route. Besides tinting the page blue, that kept the web renderer busy
/// even while the user was reading. The canvas is now a single opaque white
/// layer: no animation, shader, grid, image, or continuous repaint.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.showGrid = false,
    this.intensity = 0,
    this.animate = false,
  });

  final Widget child;

  /// Retained for source compatibility with older screen calls. The white
  /// canvas intentionally ignores all decorative options.
  final bool showGrid;
  final double intensity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.background,
      child: child,
    );
  }
}
