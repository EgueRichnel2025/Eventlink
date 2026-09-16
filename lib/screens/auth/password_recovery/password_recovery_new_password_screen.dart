import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../routes/app_routes.dart';

class PasswordRecoveryNewPasswordScreen
    extends StatefulWidget {
  final String resetToken;

  const PasswordRecoveryNewPasswordScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<PasswordRecoveryNewPasswordScreen>
      createState() =>
          _PasswordRecoveryNewPasswordScreenState();
}

class _PasswordRecoveryNewPasswordScreenState
    extends State<PasswordRecoveryNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController =
      TextEditingController();

  final _confirmationController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _changerMotDePasse() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final notifications =
        context.read<NotificationProvider>();
    final groupes = context.read<GroupProvider>();

    final succes =
        await auth.reinitialiserMotDePasse(
      resetToken: widget.resetToken,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (!succes) {
      final message = auth.errorMessage ??
          'Impossible de modifier le mot de passe.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      return;
    }

    await notifications
        .enregistrerTokenApresConnexion();

    if (!mounted) return;

    await groupes.chargerMesGroupes();

    if (!mounted) return;

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
          'Nouveau mot de passe',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        decoration: BoxDecoration(
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
                        'Créez un nouveau mot de passe',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              isSmallScreen
                                  ? 22
                                  : 27,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Choisissez un nouveau mot de passe d’au moins 8 caractères.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
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
                      'Nouveau mot de passe',
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
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.newPassword,
                      ],
                      enabled: !auth.isLoading,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Minimum 8 caractères',
                        prefixIcon: const Icon(
                          Icons
                              .lock_outline_rounded,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed:
                              auth.isLoading
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
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password =
                            value ?? '';

                        if (password.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }

                        if (password.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Confirmer le mot de passe',
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
                          _confirmationController,
                      obscureText:
                          _obscureConfirmation,
                      textInputAction:
                          TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.newPassword,
                      ],
                      enabled: !auth.isLoading,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Retapez votre mot de passe',
                        prefixIcon: const Icon(
                          Icons
                              .lock_reset_rounded,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed:
                              auth.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscureConfirmation =
                                            !_obscureConfirmation;
                                      });
                                    },
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final confirmation =
                            value ?? '';

                        if (confirmation.isEmpty) {
                          return 'Veuillez confirmer votre mot de passe';
                        }

                        if (confirmation !=
                            _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }

                        return null;
                      },
                      onFieldSubmitted:
                          auth.isLoading
                              ? null
                              : (_) =>
                                  _changerMotDePasse(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            auth.isLoading
                                ? null
                                : _changerMotDePasse,
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
                                    .check_circle_outline_rounded,
                              ),
                        label: Text(
                          auth.isLoading
                              ? 'Modification en cours...'
                              : 'Modifier le mot de passe',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .security_outlined,
                            color:
                                AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Après la modification, votre ancienne session sera invalidée et vous serez automatiquement connecté avec votre nouveau mot de passe.',
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
        ),
      ),
    );
  }
}