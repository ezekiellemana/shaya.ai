import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/radial_glow.dart';

class ShayaScreenScaffold extends StatelessWidget {
  const ShayaScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.showGlow = false,
    this.scrollable = true,
    this.safeAreaTop = true,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showGlow;
  final bool scrollable;
  final bool safeAreaTop;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ShayaTextStyles.display.copyWith(fontSize: 28)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: ShayaTextStyles.body),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(actions: actions),
        body: Stack(
          children: [
            if (showGlow)
              const Positioned(
                top: -30,
                right: -10,
                child: RadialGlow(size: 180),
              ),
            SafeArea(
              top: safeAreaTop,
              bottom: false,
              child: scrollable
                  ? SingleChildScrollView(child: content)
                  : content,
            ),
          ],
        ),
      ),
    );
  }
}
