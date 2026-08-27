import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';

/// Splash screen EventLink.
///
/// Ne se contente pas d'un "Loading..." : logo animé, identité orange/blanc,
/// puis décision de redirection selon l'état réel de la session :
///  - pas de session / pas de profil -> ProfilSetup
///  - profil OK, 0 groupe -> GroupeChoice
///  - profil OK, >=1 groupe -> GroupesScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _demarrer();
  }

  Future<void> _demarrer() async {
    // Laisse le temps à l'animation de se jouer pour une vraie identité de marque,
    // pendant que la vérification de session tourne en parallèle.
    final auth = context.read<AuthProvider>();
    final groupes = context.read<GroupProvider>();

    await Future.wait([
      auth.verifierSessionAuDemarrage(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);

    if (!mounted) return;

    if (!auth.estConnecte) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profilSetup);
      return;
    }

    await groupes.chargerMesGroupes();
    if (!mounted) return;

    if (groupes.groupes.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.groupeChoice);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.groupesScreen);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'EventLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ne perdez plus ce qui compte',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
