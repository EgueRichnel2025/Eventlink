import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/error_retry_view.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final _rechercheController = TextEditingController();

  bool _rechercheOuverte = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<GroupProvider>()
          .chargerMembresDuGroupeCourant();
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _retourAuxEvenements() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(
      AppRoutes.eventList,
    );
  }

  Future<void> _retirer(
    BuildContext context,
    String userId,
    String nom,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Retirer ce membre ?',
        ),
        content: Text(
          '$nom ne pourra plus voir les événements de ce groupe.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text(
              'Retirer',
            ),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) {
      return;
    }

    final groupProvider =
        context.read<GroupProvider>();

    await groupProvider.retirerMembre(
      userId,
    );

    if (!context.mounted) return;

    await groupProvider
        .chargerMembresDuGroupeCourant();
  }

  Future<void> _copierCodeInvitation(
    BuildContext context,
    String code,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: code),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Code d’invitation copié.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _labelRole(String role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';

      case 'admin':
        return 'Administrateur';

      default:
        return 'Membre';
    }
  }

  IconData _iconeRole(String role) {
    switch (role) {
      case 'owner':
        return Icons.workspace_premium_rounded;

      case 'admin':
        return Icons.admin_panel_settings_rounded;

      default:
        return Icons.person_rounded;
    }
  }

  Color _couleurRole(String role) {
    switch (role) {
      case 'owner':
        return AppColors.primary;

      case 'admin':
        return AppColors.primaryDark;

      default:
        return AppColors.textSecondary;
    }
  }

  String _dateCreation(DateTime date) {
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  Widget _avatarMembre({
    required String? avatarId,
    required String? photoUrl,
    required String prenom,
    double radius = 24,
  }) {
    if (avatarId != null && avatarId.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(
          'assets/images/avatars/$avatarId.jpeg',
        ),
      );
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(
          photoUrl,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        prenom.isNotEmpty
            ? prenom[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(
            width: AppSpacing.sm,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color:
                              AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupeHeader(
    BuildContext context,
    dynamic groupe,
  ) {
    final nom = groupe.nom as String;
    final code =
        groupe.codeInvitation as String;
    final nombreMembres =
        groupe.nombreMembres as int;
    final createdAt =
        groupe.createdAt as DateTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 3),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color:
                      AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: groupe.photoUrl != null &&
                        groupe.photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        child: Image.network(
                          groupe.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return Center(
                              child: Text(
                                nom.isNotEmpty
                                    ? nom[0]
                                        .toUpperCase()
                                    : '?',
                                style:
                                    const TextStyle(
                                  color: AppColors
                                      .primaryDark,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  fontSize: 28,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          nom.isNotEmpty
                              ? nom[0]
                                  .toUpperCase()
                              : '?',
                          style:
                              const TextStyle(
                            color: AppColors
                                .primaryDark,
                            fontWeight:
                                FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
              ),
              const SizedBox(
                width: AppSpacing.md,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                            color: AppColors
                                .textPrimary,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 17,
                          color: AppColors
                              .textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '$nombreMembres membre${nombreMembres > 1 ? 's' : ''}',
                            overflow:
                                TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors
                                      .textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Align(
            alignment:
                Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color:
                      AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Créé le ${_dateCreation(createdAt)}',
                    overflow:
                        TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          Container(
            padding: const EdgeInsets.all(
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.primarySurface,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.key_rounded,
                      color:
                          AppColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Code d’invitation',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                              color: AppColors
                                  .textPrimary,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _copierCodeInvitation(
                        context,
                        code,
                      ),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 17,
                      ),
                      label:
                          const Text('Copier'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        AppSpacing.md,
                    vertical: 13,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color:
                          AppColors.divider,
                    ),
                  ),
                  child: Text(
                    code,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors
                          .primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Partagez ce code avec les personnes que vous souhaitez inviter.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final iconColor = destructive
        ? AppColors.error
        : AppColors.primaryDark;

    final iconBackground = destructive
        ? AppColors.error.withValues(
            alpha: 0.10,
          )
        : AppColors.primarySurface;

    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: destructive
              ? AppColors.error.withValues(
                  alpha: 0.18,
                )
              : AppColors.divider.withValues(
                  alpha: 0.7,
                ),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 7,
            offset: Offset(0, 2),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(
                  width: AppSpacing.md,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight:
                              FontWeight.w700,
                          color: destructive
                              ? AppColors.error
                              : AppColors
                                  .textPrimary,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: AppSpacing.sm,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: destructive
                      ? AppColors.error
                      : AppColors
                          .textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestionSection(
    BuildContext context,
    dynamic groupe,
  ) {
    final estAdmin =
        groupe.estAdmin == true;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.settings_rounded,
          title: 'Gestion du groupe',
          subtitle: estAdmin
              ? 'Gérez les informations et les membres du groupe.'
              : 'Consultez les options disponibles pour votre groupe.',
        ),
        const SizedBox(
          height: AppSpacing.md,
        ),
        if (estAdmin)
          _buildGestionCard(
            icon: Icons.edit_outlined,
            title: 'Modifier le groupe',
            subtitle:
                'Modifier le nom et les informations du groupe',
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.groupSettings,
              );
            },
          ),
        _buildGestionCard(
          icon: Icons.people_alt_outlined,
          title: 'Gérer les membres',
          subtitle:
              'Rechercher, consulter et gérer les membres du groupe',
          onTap: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pushNamed(
              AppRoutes.groupManageMembers,
            );
          },
        ),
        if (estAdmin)
          _buildGestionCard(
            icon:
                Icons.admin_panel_settings_outlined,
            title: 'Administrateurs',
            subtitle:
                'Promouvoir ou rétrograder les administrateurs du groupe',
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.groupAdministrators,
              );
            },
          ),
        _buildGestionCard(
          icon: Icons.logout_rounded,
          title: 'Quitter le groupe',
          subtitle:
              'Quitter définitivement ce groupe',
          destructive: true,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.groupLeave,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupe =
        context.watch<GroupProvider>().groupeCourant;

    final moi =
        context.watch<AuthProvider>().currentUser;

    if (groupe == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: const Color(0x22000000),
          title: const Text(
            'Mon groupe',
          ),
          leading: IconButton(
            onPressed:
                _retourAuxEvenements,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            tooltip:
                'Retour aux événements',
          ),
        ),
        body: const Center(
          child: Text(
            'Aucun groupe sélectionné.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: const Color(0x22000000),
        title: _rechercheOuverte
            ? TextField(
                controller:
                    _rechercheController,
                autofocus: true,
                style: const TextStyle(
                  color:
                      AppColors.textPrimary,
                ),
                decoration:
                    const InputDecoration(
                  hintText:
                      'Rechercher un membre...',
                  hintStyle: TextStyle(
                    color:
                        AppColors.textSecondary,
                  ),
                  border:
                      InputBorder.none,
                ),
                onChanged: (value) {
                  final provider =
                      context.read<
                          GroupProvider>();

                  provider
                      .definirRechercheMembres(
                    value,
                  );

                  provider
                      .chargerMembresDuGroupeCourant();
                },
              )
            : const Text(
                'Mon groupe',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
        leading: IconButton(
          onPressed:
              _retourAuxEvenements,
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          tooltip:
              'Retour aux événements',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _rechercheOuverte
                  ? Icons.close_rounded
                  : Icons.search_rounded,
            ),
            tooltip: _rechercheOuverte
                ? 'Fermer la recherche'
                : 'Rechercher un membre',
            onPressed: () {
              setState(() {
                _rechercheOuverte =
                    !_rechercheOuverte;

                if (!_rechercheOuverte) {
                  _rechercheController.clear();

                  final provider =
                      context.read<
                          GroupProvider>();

                  provider
                      .definirRechercheMembres(
                    '',
                  );

                  provider
                      .chargerMembresDuGroupeCourant();
                }
              });
            },
          ),
          if (groupe.estAdmin == true)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
              ),
              tooltip:
                  'Paramètres du groupe',
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(
                  AppRoutes.groupSettings,
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder:
            (context, provider, _) {
          if (provider.isLoading &&
              provider.membresDuGroupeCourant
                  .isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null &&
              provider
                  .membresDuGroupeCourant
                  .isEmpty) {
            return ErrorRetryView(
              message:
                  provider.errorMessage!,
              onRetry: provider
                  .chargerMembresDuGroupeCourant,
            );
          }

          final membres =
              provider.membresDuGroupeCourant;

          return RefreshIndicator(
            onRefresh: () async {
              await provider
                  .chargerMembresDuGroupeCourant();
            },
            child: ListView(
              padding:
                  const EdgeInsets.all(
                AppSpacing.lg,
              ),
              children: [
                _buildGroupeHeader(
                  context,
                  groupe,
                ),
                const SizedBox(
                  height: AppSpacing.xl,
                ),
                _sectionTitle(
                  icon:
                      Icons.people_alt_rounded,
                  title: 'Membres',
                  subtitle:
                      '${membres.length} membre${membres.length > 1 ? 's' : ''} affiché${membres.length > 1 ? 's' : ''}',
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                if (membres.isEmpty)
                  Container(
                    padding:
                        const EdgeInsets.all(
                      AppSpacing.xl,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child:
                        const Column(
                      children: [
                        Icon(
                          Icons
                              .people_outline_rounded,
                          size: 44,
                          color: AppColors
                              .textSecondary,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Aucun membre trouvé',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...membres.map(
                    (membre) {
                      final estMoi =
                          membre.userId ==
                              moi?.id;

                      final roleColor =
                          _couleurRole(
                        membre.role,
                      );

                      return Card(
                        margin:
                            const EdgeInsets
                                .only(
                          bottom:
                              AppSpacing.sm,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                AppSpacing.md,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _avatarMembre(
                                avatarId:
                                    membre.avatarId,
                                photoUrl:
                                    membre.photoUrl,
                                prenom:
                                    membre.prenom,
                                radius: 25,
                              ),
                              const SizedBox(
                                width:
                                    AppSpacing.md,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      estMoi
                                          ? '${membre.nomComplet} (moi)'
                                          : membre
                                              .nomComplet,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: AppColors
                                            .textPrimary,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          _iconeRole(
                                            membre
                                                .role,
                                          ),
                                          size: 15,
                                          color:
                                              roleColor,
                                        ),
                                        const SizedBox(
                                            width: 5),
                                        Flexible(
                                          child:
                                              Text(
                                            _labelRole(
                                              membre
                                                  .role,
                                            ),
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  13,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              color:
                                                  roleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (groupe
                                          .estAdmin ==
                                      true &&
                                  !estMoi &&
                                  membre.role ==
                                      'member')
                                TextButton.icon(
                                  onPressed: () =>
                                      _retirer(
                                    context,
                                    membre.userId,
                                    membre
                                        .nomComplet,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons
                                        .person_remove_outlined,
                                    color:
                                        AppColors
                                            .error,
                                    size: 18,
                                  ),
                                  label:
                                      const Text(
                                    'Retirer',
                                    style:
                                        TextStyle(
                                      color:
                                          AppColors
                                              .error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(
                  height: AppSpacing.xl,
                ),
                _buildGestionSection(
                  context,
                  groupe,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}