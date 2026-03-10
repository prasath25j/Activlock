import 'package:flutter/material.dart';
import '../theme/arctic_theme.dart';
import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Physical Unlock",
      description: "Access your most distracting apps only after completing physical exercises like Squats or Pushups.",
      icon: Icons.fitness_center_rounded,
      color: ArcticTheme.frostBlue,
    ),
    OnboardingData(
      title: "Security Logic",
      description: "Set custom patterns and PINs to ensure only you can override the protocols.",
      icon: Icons.security_rounded,
      color: ArcticTheme.deepNavy,
    ),
    OnboardingData(
      title: "Intruder Alert",
      description: "ActivLock secretly captures photos of anyone attempting to bypass your security protocols.",
      icon: Icons.camera_front_rounded,
      color: ArcticTheme.frostBlue,
    ),
  ];

  void _finish() async {
    await SettingsService().setFirstLaunchComplete();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArcticTheme.iceWhite,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, idx) {
              final page = _pages[idx];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: page.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(page.icon, size: 100, color: page.color),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      page.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: ArcticTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ArcticTheme.softSlate,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(_pages.length, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? ArcticTheme.frostBlue : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                
                // Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArcticTheme.deepNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(_currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT"),
                ),
              ],
            ),
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

  OnboardingData({required this.title, required this.description, required this.icon, required this.color});
}
