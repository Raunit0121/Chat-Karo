import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to ChatKaro!',
      description: 'Connect, chat, and share moments with friends and family.',
      lottieAsset: 'assets/lottie/chat.json',
      gradient: LinearGradient(colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)]),
    ),
    _OnboardingPageData(
      title: 'Fast & Secure',
      description: 'Enjoy seamless and secure messaging with end-to-end encryption.',
      lottieAsset: 'assets/lottie/secure.json',
      gradient: LinearGradient(colors: [Color(0xFF43CEA2), Color(0xFF185A9D)]),
    ),
    _OnboardingPageData(
      title: 'Personalize Your Profile',
      description: 'Set your avatar, update your info, and make ChatKaro yours!',
      lottieAsset: 'assets/lottie/profile.json',
      gradient: LinearGradient(colors: [Color(0xFFFFAF7B), Color(0xFFD76D77), Color(0xFF3A1C71)]),
    ),
    _OnboardingPageData(
      title: 'Get Started!',
      description: 'Sign up or log in to begin your journey.',
      lottieAsset: 'assets/lottie/start.json',
      gradient: LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: page.gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip and Page Counter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      '${_currentPage + 1}/${_pages.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) => _buildPage(_pages[index]),
                ),
              ),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) => _buildDot(index)),
              ),

              const SizedBox(height: 32),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: _currentPage == _pages.length - 1
                    ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                              fontSize: 18,
                              color: page.gradient.colors.first,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(
                          fontSize: 18,
                          color: page.gradient.colors.first,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData p) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          p.lottieAsset,
          height: 220,
          repeat: true,
        ),
        const SizedBox(height: 32),
        Text(
          p.title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            p.description,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _currentPage == index ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final String lottieAsset;
  final Gradient gradient;

  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.gradient,
  });
}
