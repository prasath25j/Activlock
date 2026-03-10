import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "REDEMPTION OVER RESTRICTION",
      description: "ActivLock doesn't just block apps. It requires you to earn your screen time through physical effort.",
      icon: Icons.shield_rounded,
      color: ModernTheme.primaryBlue,
    ),
    OnboardingData(
      title: "AI POSE DETECTION",
      description: "Unlock apps by performing squats or pushups. Our AI tracks your form in real-time using the front or back camera.",
      icon: Icons.fitness_center_rounded,
      color: ModernTheme.accentPink,
    ),
    OnboardingData(
      title: "STEP CHALLENGE",
      description: "Need a different pace? Set a step goal to unlock your applications and stay active throughout the day.",
      icon: Icons.directions_walk_rounded,
      color: ModernTheme.accentCyan,
    ),
    OnboardingData(
      title: "SMART GOVERNANCE",
      description: "Configure custom rep targets, daily unlock limits, and specific unlock durations for every protected app.",
      icon: Icons.settings_suggest_rounded,
      color: Colors.orangeAccent,
    ),
  ];

  void _onFinish() async {
    await ref.read(settingsServiceProvider).setFirstLaunchComplete();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WakandaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return _buildPage(data);
                  },
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(40),
            opacity: 0.1,
            blur: 20,
            color: data.color,
            child: Icon(data.icon, size: 80, color: data.color),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isLastPage = _currentPage == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicator
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index 
                      ? ModernTheme.primaryBlue 
                      : Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ),
          // Action Button
          ElevatedButton(
            onPressed: isLastPage ? _onFinish : () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: isLastPage ? ModernTheme.accentPink : ModernTheme.primaryBlue,
            ),
            child: Text(isLastPage ? "GET STARTED" : "NEXT"),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
