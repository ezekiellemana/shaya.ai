import 'package:flutter/material.dart';

class ShayaShimmer extends StatefulWidget {
  const ShayaShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<ShayaShimmer> createState() => _ShayaShimmerState();
}

class _ShayaShimmerState extends State<ShayaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + (_controller.value * 2), -0.25),
              end: Alignment(0.2 + (_controller.value * 2), 0.25),
              colors: const [
                Color(0x24FFFFFF),
                Color(0x55FFFFFF),
                Color(0x24FFFFFF),
              ],
              stops: const [0.12, 0.34, 0.56],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class ShayaSkeletonBlock extends StatelessWidget {
  const ShayaSkeletonBlock({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 12,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return ShayaShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(radius),
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
