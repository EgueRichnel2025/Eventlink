import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class PasswordRecoveryEmailScreen
    extends StatefulWidget {
  const PasswordRecoveryEmailScreen({
    super.key,
  });

  @override
  State<PasswordRecoveryEmailScreen> createState() =>
      _PasswordRecoveryEmailScreenState();
}

class _PasswordRecoveryEmailScreenState
    extends State<PasswordRecoveryEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final succes =
        await auth.demanderCodeRecuperation(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (!succes) {
      final message = auth.errorMessage ??
          'Impossible d’envoyer le code de récupération.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.passwordRecoveryCode,
      arguments: _emailController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width < 360;
    final horizontalPadding =
        isSmallScreen ? 16.0 : 24.0;

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Récupération du mot de passe',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                size.height < 650 ? 16 : 28,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 560,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width:
                                isSmallScreen ? 68 : 80,
                            height:
                                isSmallScreen ? 68 : 80,
                            decoration:
                                BoxDecoration(
                              color: AppColors.primary
                                  .withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons
                                  .lock_reset_rounded,
                              color:
                                  AppColors.primary,
                              size:
                                  isSmallScreen
                                      ? 34
                                      : 40,
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              size.height < 650
                                  ? 20
                                  : 28,
                        ),
                        Center(
                          child: Text(
                            'Mot de passe oublié ?',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  isSmallScreen
                                      ? 23
                                      : 28,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: Text(
                            'Entrez l’adresse e-mail associée à votre compte. Nous vous enverrons un code de récupération.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize:
                                  isSmallScreen
                                      ? 14
                                      : 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              size.height < 650
                                  ? 28
                                  : 40,
                        ),
                        const Text(
                          'Adresse e-mail',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:
                              _emailController,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          textInputAction:
                              TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          enabled: !auth.isLoading,
                          decoration:
                              const InputDecoration(
                            hintText:
                                'Entrez votre adresse e-mail',
                            prefixIcon: Icon(
                              Icons
                                  .email_outlined,
                            ),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'L’adresse e-mail est obligatoire';
                            }

                            final emailRegex =
                                RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!emailRegex
                                .hasMatch(email)) {
                              return 'Entrez une adresse e-mail valide';
                            }

                            return null;
                          },
                          onFieldSubmitted:
                              auth.isLoading
                                  ? null
                                  : (_) =>
                                      _envoyerCode(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                auth.isLoading
                                    ? null
                                    : _envoyerCode,
                            icon: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .mark_email_read_outlined,
                                  ),
                            label: Text(
                              auth.isLoading
                                  ? 'Envoi en cours...'
                                  : 'Recevoir le code',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed:
                                auth.isLoading
                                    ? null
                                    : () {
                                        Navigator.of(
                                          context,
                                        ).pop();
                                      },
                            icon: const Icon(
                              Icons
                                  .arrow_back_rounded,
                            ),
                            label: const Text(
                              'Retour à la connexion',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors
                                .primarySurface,
                            borderRadius:
                                BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                          child:const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                               Icon(
                                Icons
                                    .info_outline_rounded,
                                color:
                                    AppColors.primary,
                                size: 20,
                              ),
                               SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'L’adresse e-mail est utilisée uniquement pour récupérer votre mot de passe.',
                                  style: TextStyle(
                                    color: AppColors
                                        .textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}