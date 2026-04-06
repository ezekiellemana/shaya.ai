import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/mini_player_bar.dart';

class ShayaShellScaffold extends StatelessWidget {
  const ShayaShellScaffold({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(),
            _BottomNavigation(location: location),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexForLocation(location);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kSurfaceDark.withValues(alpha: 0.96),
                    kSurface.withValues(alpha: 0.84),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  _NavItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => context.go('/home'),
                  ),
                  _NavItem(
                    label: 'Library',
                    icon: Icons.library_music_rounded,
                    selected: currentIndex == 1,
                    onTap: () => context.go('/library'),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go('/generate'),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: kGradAccent,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryPurple.withValues(alpha: 0.30),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _NavItem(
                    label: 'Search',
                    icon: Icons.search_rounded,
                    selected: currentIndex == 2,
                    onTap: () => context.go('/search'),
                  ),
                  _NavItem(
                    label: 'Profile',
                    icon: Icons.person_rounded,
                    selected: currentIndex == 3,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/library')) {
      return 1;
    }
    if (location.startsWith('/search')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kPurpleLight : kTextMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: ShayaTextStyles.metadata.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
