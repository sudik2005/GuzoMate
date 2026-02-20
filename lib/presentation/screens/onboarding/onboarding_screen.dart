import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:byure/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimationController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Discover Nearby Walkers',
      description: 'Find people in your area who love walking just like you.',
      icon: Icons.explore_outlined,
      color: AppTheme.primaryGreen,
    ),
    OnboardingPage(
      title: 'Find Walking Buddies',
      description: 'Connect with people who share your walking pace and interests.',
      icon: Icons.people_outline,
      color: AppTheme.primaryTeal,
    ),
    OnboardingPage(
      title: 'Walk Safely Together',
      description: 'Never walk alone. Explore routes and stay safe with your buddies.',
      icon: Icons.directions_walk,
      color: Color(0xFF00B0FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(_pages[_currentPage].color.withValues(alpha: 0.1), Colors.white, 0.5)!,
                      Color.lerp(Colors.white, _pages[_currentPage].color.withValues(alpha: 0.2), 0.5)!,
                    ],
                    transform: GradientRotation(_bgAnimationController.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),
          
          // Content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageView(
                      page: _pages[index],
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),

              // Bottom Control Area
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotColor: Colors.black12,
                        activeDotColor: _pages[_currentPage].color,
                        dotHeight: 10,
                        dotWidth: 10,
                        spacing: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuint,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            elevation: 8,
                            shadowColor: _pages[_currentPage].color.withValues(alpha: 0.4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_currentPage < _pages.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.arrow_forward_rounded, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;
  final bool isActive;

  const _OnboardingPageView({
    required this.page,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            height: isActive ? 280 : 200,
            width: isActive ? 280 : 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: isActive ? 120 : 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 64),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -1,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.5,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

