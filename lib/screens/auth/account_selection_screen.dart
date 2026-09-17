import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/stored_account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';

enum _PasswordDialogResult {
  password,
  recovery,
}

class AccountSelectionScreen extends StatefulWidget {
  const AccountSelectionScreen({super.key});

  @override
  State<AccountSelectionScreen> createState() =>
      _AccountSelectionScreenState();
}

class _AccountSelectionScreenState
    extends State<AccountSelectionScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AuthProvider>().chargerComptesConnus();
    });
  }

  Future<void> _connecterCompte(
    StoredAccount account,
  ) async {
    final result = await _afficherDialogueMotDePasse(
      account,
    );

    if (!mounted || result == null) return;

    if (result.result ==
        _PasswordDialogResult.recovery) {
      Navigator.of(context).pushNamed(
        AppRoutes.passwordRecoveryEmail,
      );

      return;
    }

    final password = result.password;

    if (password == null || password.isEmpty) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final notifications =
        context.read<NotificationProvider>();
    final groupes = context.read<GroupProvider>();

    final success = await auth.connecterCompte(
      userId: account.user.id,
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      final message = auth.errorMessage ??
          'Impossible de connecter ce compte.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      return;
    }

    await notifications.enregistrerTokenApresConnexion();

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

  Future<_PasswordDialogResultData?>
      _afficherDialogueMotDePasse(
    StoredAccount account,
  ) async {
    final screenSize = MediaQuery.sizeOf(context);

    return showDialog<_PasswordDialogResultData>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PasswordDialog(
          account: account,
          screenSize: screenSize,
        );
      },
    );
  }

  void _creerNouveauCompte() {
    final auth = context.read<AuthProvider>();

    if (!auth.peutAjouterCompte) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous pouvez enregistrer au maximum 3 comptes sur cet appareil.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.profilSetup,
    );
  }

  Widget _buildAvatar(
    StoredAccount account, {
    required double size,
  }) {
    final user = account.user;

    if (user.avatarId != null &&
        user.avatarId!.isNotEmpty) {
      final avatarNumber = int.tryParse(
        user.avatarId!.replaceAll(
          'avatar_',
          '',
        ),
      );

      if (avatarNumber != null &&
          avatarNumber >= 1 &&
          avatarNumber <= 66) {
        final assetName =
            'assets/images/avatars/avatar_${avatarNumber.toString().padLeft(2, '0')}.jpeg';

        return ClipOval(
          child: Image.asset(
            assetName,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _buildInitiales(
                user.prenom,
                user.nom,
                size: size,
              );
            },
          ),
        );
      }
    }

    return _buildInitiales(
      user.prenom,
      user.nom,
      size: size,
    );
  }

  Widget _buildInitiales(
    String prenom,
    String nom, {
    required double size,
  }) {
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}'
        '${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    final fontSize = size < 52 ? 16.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initiales,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    StoredAccount account, {
    required double avatarSize,
  }) {
    return InkWell(
      onTap: context
              .watch<AuthProvider>()
              .isLoading
          ? null
          : () => _connecterCompte(account),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary
                .withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(
              account,
              size: avatarSize,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${account.user.prenom} ${account.user.nom}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyer pour continuer',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(
                            alpha: 0.65,
                          ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);

    final isSmallScreen =
        size.width < 360;

    final horizontalPadding =
        isSmallScreen ? 16.0 : 24.0;

    final topSpacing =
        size.height < 650 ? 12.0 : 20.0;

    final iconSize =
        size.width < 360 ? 58.0 : 72.0;

    final titleSize =
        size.width < 360 ? 22.0 : 26.0;

    final avatarSize =
        size.width < 360 ? 50.0 : 56.0;

    final peutCreerCompte =
        auth.peutAjouterCompte;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Choisir un compte',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topSpacing,
                horizontalPadding,
                16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(
                          Icons
                              .account_circle_rounded,
                          color:
                              AppColors.primary,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(
                        height:
                            size.height < 650
                                ? 16
                                : 24,
                      ),
                      Center(
                        child: Text(
                          'Bienvenue sur EventLink',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: Text(
                          'Choisissez un compte pour continuer',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(
                                  alpha: 0.7,
                                ),
                            fontSize:
                                isSmallScreen
                                    ? 14
                                    : 15,
                          ),
                        ),
                      ),
                      SizedBox(
                        height:
                            size.height < 650
                                ? 20
                                : 32,
                      ),
                      if (auth.comptesConnus
                          .isEmpty)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 24,
                          ),
                          child: Center(
                            child: Text(
                              'Aucun compte enregistré sur cet appareil.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              auth.comptesConnus
                                  .length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                                height: 12,
                              ),
                          itemBuilder:
                              (context, index) {
                            return _buildAccountCard(
                              auth.comptesConnus[
                                  index],
                              avatarSize:
                                  avatarSize,
                            );
                          },
                        ),
                      const SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              auth.isLoading ||
                                      !peutCreerCompte
                                  ? null
                                  : _creerNouveauCompte,
                          icon: const Icon(
                            Icons
                                .person_add_alt_1_rounded,
                          ),
                          label: Text(
                            peutCreerCompte
                                ? 'Créer un nouveau compte'
                                : 'Limite de 3 comptes atteinte',
                          ),
                          style: OutlinedButton
                              .styleFrom(
                            foregroundColor:
                                AppColors.primary,
                            disabledForegroundColor:
                                Theme.of(
                              context,
                            )
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(
                                      alpha: 0.45,
                                    ),
                            side:
                                const BorderSide(
                              color:
                                  AppColors.primary,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 15,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .pushNamed(
                                    AppRoutes.login,
                                  );
                                },
                          icon: const Icon(
                            Icons.email_outlined,
                          ),
                          label: const Text(
                            'Utiliser une autre adresse email',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (!peutCreerCompte) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: Text(
                            'Supprimez un compte de cet appareil avant d’en ajouter un nouveau.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(
                                    alpha: 0.65,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _PasswordDialog extends StatefulWidget {
  final StoredAccount account;
  final Size screenSize;

  const _PasswordDialog({
    required this.account,
    required this.screenSize,
  });

  @override
  State<_PasswordDialog> createState() =>
      _PasswordDialogState();
}

class _PasswordDialogState
    extends State<_PasswordDialog> {
  late final TextEditingController _controller;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fermerAvecMotDePasse() {
    if (_controller.text.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _PasswordDialogResultData(
        result: _PasswordDialogResult.password,
        password: _controller.text,
      ),
    );
  }

  void _fermerPourRecuperation() {
    Navigator.of(context).pop(
      const _PasswordDialogResultData(
        result: _PasswordDialogResult.recovery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen =
        widget.screenSize.width < 360;

    final auth =
        context.watch<AuthProvider>();

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal:
            isSmallScreen ? 16 : 24,
        vertical: 24,
      ),
      titlePadding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        8,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        0,
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connexion',
              style: TextStyle(
                fontSize:
                    isSmallScreen ? 19 : 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour ${widget.account.user.prenom} 👋',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre mot de passe pour continuer.',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: _obscurePassword,
                enabled: !auth.isLoading,
                textInputAction:
                    TextInputAction.done,
                autofillHints: const [
                  AutofillHints.password,
                ],
                onChanged: (_) {
                  setState(() {});
                },
                onSubmitted:
                    _controller.text.isEmpty
                        ? null
                        : (_) {
                            _fermerAvecMotDePasse();
                          },
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize:
                      isSmallScreen ? 16 : 17,
                ),
                cursorColor:
                    AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText:
                      'Entrez votre mot de passe',
                  prefixIcon:
                      const Icon(
                    Icons.lock_outline_rounded,
                  ),
                  suffixIcon: IconButton(
                    onPressed: auth.isLoading
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
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre mot de passe est utilisé pour sécuriser l’accès à ce compte.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : _fermerPourRecuperation,
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
                        const EdgeInsets
                            .symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
              if (auth.isLoading) ...[
                const SizedBox(height: 12),
                const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      actions: [
        TextButton(
          onPressed: auth.isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton(
          onPressed:
              _controller.text.isEmpty ||
                      auth.isLoading
                  ? null
                  : _fermerAvecMotDePasse,
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.primary,
          ),
          child: const Text(
            'Se connecter',
          ),
        ),
      ],
    );
  }
}

class _PasswordDialogResultData {
  final _PasswordDialogResult result;
  final String? password;

  const _PasswordDialogResultData({
    required this.result,
    this.password,
  });
}
