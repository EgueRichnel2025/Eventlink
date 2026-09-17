import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final notifications =
        context.read<NotificationProvider>();
    final groupes = context.read<GroupProvider>();

    setState(() => _isLoading = true);

    final succes = await auth.connecterAvecEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!succes) {
      setState(() => _isLoading = false);

      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
          ),
        );
      }

      return;
    }

    // Le JWT vient d'être enregistré par AuthService.
    // On peut maintenant enregistrer le token FCM.
    await notifications.enregistrerTokenApresConnexion();

    if (!mounted) return;

    await groupes.chargerMesGroupes();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (groupes.groupes.isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.groupeChoice,
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.groupesScreen,
        (route) => false,
      );
    }
  }

  void _motDePasseOublie() {
    Navigator.of(context).pushNamed(
      AppRoutes.passwordRecoveryEmail,
    );
  }

  void _creerCompte() {
    Navigator.of(context).pushNamed(
      AppRoutes.profilSetup,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.white70,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/backgrounds/profile_background.jpeg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - 52,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 440,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(
                                          context,
                                        ).pop();
                                      },
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.login_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Bon retour !',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connectez-vous à votre compte EventLink',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.82,
                                ),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                hintText: 'Adresse email',
                                prefixIcon:
                                    Icons.email_outlined,
                              ),
                              validator: (value) {
                                final email =
                                    value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Veuillez entrer votre adresse email.';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Veuillez entrer une adresse email valide.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _seConnecter();
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: 'Mot de passe',
                                prefixIcon:
                                    Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _motDePasseOublie,
                                icon: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Mot de passe oublié ?',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _isLoading
                                    ? null
                                    : _seConnecter,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'Nouveau sur EventLink ?',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _creerCompte,
                              icon: const Icon(
                                Icons.person_add_alt_1_rounded,
                              ),
                              label: const Text(
                                'Créer un compte',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white
                                      .withValues(alpha: 0.6),
                                ),
                                minimumSize:
                                    const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
