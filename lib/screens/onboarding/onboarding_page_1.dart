import 'package:flutter/material.dart';

import '../../config/theme.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond plein écran
          Image.asset(
            'assets/images/onboarding/onboarding_01_problem.jpeg',
            fit: BoxFit.cover,
          ),

          // Overlay sombre pour améliorer la lisibilité
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // Contenu
         const Padding(
            padding:  EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 Text(
                  'Ne ratez plus aucune opportunité',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md),
                 Text(
                  'Les formations, hackathons, bourses et événements sont dispersés partout. '
                  'Il est facile de manquer des opportunités importantes simplement parce qu\'elles '
                  'sont difficiles à retrouver.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
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