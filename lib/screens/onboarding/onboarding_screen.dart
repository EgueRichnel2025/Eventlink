import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'onboarding_page_1.dart';
import 'onboarding_page_2.dart';
import 'onboarding_page_3.dart';
import 'onboarding_page_4.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingCompleted() async {
    final storage = StorageService();
    await storage.markOnboardingCompleted();
  }

  Future<void> _continuer() async {
    setState(() => _isLoading = true);

    // Mark onboarding as completed
    await _markOnboardingCompleted();
    if (!mounted) return;
    // Check if user already has a profile
    final auth = context.read<AuthProvider>();
    final hasProfile = await auth.hasProfile();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (hasProfile) {
      // User has profile, go to group choice
      Navigator.of(context).pushReplacementNamed('/groupe-choice');
    } else {
      // User needs to create profile
      Navigator.of(context).pushReplacementNamed('/profil-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: const [
              OnboardingPage1(),
              OnboardingPage2(),
              OnboardingPage3(),
              OnboardingPage4(),
            ],
          ),
          // Skip button (always visible in top right)
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: TextButton(
              onPressed: _continuer,
              child: const Text(
                'Passer',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          // Page indicator and continue button (at bottom)
          Positioned(
            bottom: AppSpacing.lg,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => Container(
                      width: _currentPage == index ? 12 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Continue button (only show on last page)
                  if (_currentPage == 3)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continuer,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Commencer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}