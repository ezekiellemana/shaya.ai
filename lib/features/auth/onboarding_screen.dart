import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Set<String> _selectedGenres = <String>{};
  String _selectedMood = AppConstants.moods.first;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) =>
                        setState(() => _currentPage = value),
                    children: [
                      _OnboardingPage(
                        title: 'Create with a Tanzanian pulse',
                        description:
                            'Shaya AI is your Afrofuturist studio for music, video, and lyrics in English or Swahili.',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: kGradCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: kPurpleLight.withValues(alpha: 0.20),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _OnboardingPage(
                        title: 'Pick your favorite genres',
                        description:
                            'These guide featured ideas and future prompts.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.genreTags.map((genre) {
                            return ShayaChip(
                              label: genre,
                              selected: _selectedGenres.contains(genre),
                              onTap: () {
                                setState(() {
                                  if (_selectedGenres.contains(genre)) {
                                    _selectedGenres.remove(genre);
                                  } else {
                                    _selectedGenres.add(genre);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      _OnboardingPage(
                        title: 'Choose the mood you return to most',
                        description:
                            'We use this for a smarter first-home experience.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.moods.map((mood) {
                            return ShayaChip(
                              label: mood,
                              selected: _selectedMood == mood,
                              isMood: true,
                              onTap: () => setState(() => _selectedMood = mood),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _currentPage == index
                            ? kPurpleLight
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryGradientButton(
                  label: _currentPage == 2 ? 'Start Creating' : 'Continue',
                  onPressed: () async {
                    if (_currentPage == 2) {
                      await _finishOnboarding();
                      return;
                    }
                    await _pageController.nextPage(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    await ref
        .read(appSessionControllerProvider)
        .completeOnboarding(
          genres: _selectedGenres.toList(),
          mood: _selectedMood,
        );
    if (!mounted) {
      return;
    }
    context.go('/login');
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: ShayaTextStyles.display),
        const SizedBox(height: 12),
        Text(description, style: ShayaTextStyles.body),
        const SizedBox(height: 32),
        child,
      ],
    );
  }
}
