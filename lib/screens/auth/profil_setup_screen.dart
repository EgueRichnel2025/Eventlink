import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfilSetupScreen extends StatefulWidget {
  const ProfilSetupScreen({super.key});

  @override
  State<ProfilSetupScreen> createState() => _ProfilSetupScreenState();
}

class _ProfilSetupScreenState extends State<ProfilSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();

  final _scrollController = ScrollController();
  final _formFieldsKey = GlobalKey();

  String? _selectedAvatarId;
  bool _useInitials = false;
  bool _showAvatarGrid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();

    final succes = await auth.creerProfil(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      avatarId: _useInitials ? null : _selectedAvatarId,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (succes) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.groupeChoice,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
        ),
      );
    }
  }

  void _choisirAvatar() {
    setState(() {
      _useInitials = false;
      _showAvatarGrid = true;
    });
  }

  void _choisirInitiales() {
    setState(() {
      _useInitials = true;
      _selectedAvatarId = null;
      _showAvatarGrid = false;
    });

    _descendreVersLeFormulaire();
  }

  void _selectionnerAvatar(String avatarId) {
    setState(() {
      _selectedAvatarId = avatarId;
      _useInitials = false;
      _showAvatarGrid = true;
    });

    _descendreVersLeFormulaire();
  }

  void _descendreVersLeFormulaire() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final context = _formFieldsKey.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - (AppSpacing.lg * 2),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            Text(
                              'Faisons connaissance',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 700,
                              ),
                              child: Text(
                                'Ces informations identifieront vos événements et vos commentaires auprès des autres membres.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // -------------------------------------------------
                            // CHOIX DE LA PHOTO DE PROFIL
                            // -------------------------------------------------
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Photo de profil',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // -------------------------------------------------
                            // LES DEUX CHOIX UTILISENT LE MÊME RADIO GROUP
                            // -------------------------------------------------
                            RadioGroup<bool>(
                              groupValue: _useInitials,
                              onChanged: (value) {
                                if (value == null) return;

                                if (value) {
                                  _choisirInitiales();
                                } else {
                                  _choisirAvatar();
                                }
                              },
                              child: Column(
                                children: [
                                  // -------------------------------------------------
                                  // CHOISIR UN AVATAR
                                  // -------------------------------------------------
                                  InkWell(
                                    onTap: _choisirAvatar,
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: !_useInitials
                                            ? AppColors.primary.withValues(
                                                alpha: 0.18,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                          color: !_useInitials
                                              ? AppColors.primary
                                              : Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                          width: !_useInitials ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(
                                                alpha: 0.18,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.face_rounded,
                                              color: Colors.white,
                                            ),
                                          ),

                                          const SizedBox(width: 14),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Choisir un avatar pour la photo de profil',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Sélectionnez l’un des avatars proposés.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white
                                                            .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const Radio<bool>(
                                            value: false,
                                            activeColor:
                                                AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // -------------------------------------------------
                                  // GRILLE DES AVATARS
                                  // APPARAÎT UNIQUEMENT APRÈS CLIC
                                  // -------------------------------------------------
                                  AnimatedSize(
                                    duration:
                                        const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut,
                                    child: _showAvatarGrid
                                        ? Column(
                                            children: [
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),

                                              LayoutBuilder(
                                                builder: (
                                                  context,
                                                  gridConstraints,
                                                ) {
                                                  final width =
                                                      gridConstraints.maxWidth;

                                                  int crossAxisCount;

                                                  if (width >= 1200) {
                                                    crossAxisCount = 6;
                                                  } else if (width >= 900) {
                                                    crossAxisCount = 5;
                                                  } else if (width >= 600) {
                                                    crossAxisCount = 4;
                                                  } else if (width >= 400) {
                                                    crossAxisCount = 3;
                                                  } else {
                                                    crossAxisCount = 2;
                                                  }

                                                  return GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount:
                                                          crossAxisCount,
                                                      crossAxisSpacing: 10,
                                                      mainAxisSpacing: 10,
                                                      childAspectRatio: 1,
                                                    ),
                                                    itemCount: 66,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final avatarNumber =
                                                          index + 1;

                                                      final avatarId =
                                                          'avatar_${avatarNumber.toString().padLeft(2, '0')}';

                                                      final isSelected =
                                                          avatarId ==
                                                              _selectedAvatarId;

                                                      return GestureDetector(
                                                        onTap: () {
                                                          _selectionnerAvatar(
                                                            avatarId,
                                                          );
                                                        },
                                                        child:
                                                            AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                            milliseconds: 180,
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(
                                                            3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : Colors
                                                                      .transparent,
                                                              width: 3,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              14,
                                                            ),
                                                            color: isSelected
                                                                ? AppColors
                                                                    .primarySurface
                                                                : Colors.white
                                                                    .withValues(
                                                                    alpha:
                                                                        0.1,
                                                                  ),
                                                            boxShadow:
                                                                isSelected
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: AppColors
                                                                              .primary
                                                                              .withValues(
                                                                            alpha:
                                                                                0.35,
                                                                          ),
                                                                          blurRadius:
                                                                              10,
                                                                          spreadRadius:
                                                                              1,
                                                                        ),
                                                                      ]
                                                                    : null,
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  10,
                                                                ),
                                                                child:
                                                                    SizedBox
                                                                        .expand(
                                                                  child:
                                                                      Image.asset(
                                                                    'assets/images/avatars/$avatarId.jpeg',
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                              if (isSelected)
                                                                Positioned(
                                                                  bottom: 6,
                                                                  right: 6,
                                                                  child:
                                                                      Container(
                                                                    width: 26,
                                                                    height: 26,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: AppColors
                                                                          .primary,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border:
                                                                          Border.all(
                                                                        color: Colors
                                                                            .white,
                                                                        width:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .check,
                                                                      size: 16,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),

                                              const SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  // -------------------------------------------------
                                  // OU
                                  // -------------------------------------------------
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          'OU',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.75,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  // -------------------------------------------------
                                  // CHOISIR LES INITIALES
                                  // -------------------------------------------------
                                  InkWell(
                                    onTap: _choisirInitiales,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _useInitials
                                            ? AppColors.primary.withValues(
                                                alpha: 0.18,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _useInitials
                                              ? AppColors.primary
                                              : Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                          width: _useInitials ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(
                                                alpha: 0.18,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.text_fields_rounded,
                                              color: Colors.white,
                                            ),
                                          ),

                                          const SizedBox(width: 14),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Choisir mes initiales pour la photo de profil',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Vos initiales seront utilisées comme photo de profil.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white
                                                            .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const Radio<bool>(
                                            value: true,
                                            activeColor:
                                                AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // -------------------------------------------------
                            // PRÉNOM + NOM
                            // -------------------------------------------------
                            Container(
                              key: _formFieldsKey,
                              child: Column(
                                children: [
                                  // -------------------------------------------------
                                  // PRÉNOM
                                  // -------------------------------------------------
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Prénom',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  TextFormField(
                                    controller: _prenomController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Entrez votre prénom',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white70,
                                      ),
                                      suffixIcon:
                                          _prenomController.text.isNotEmpty
                                              ? IconButton(
                                                  onPressed: () {
                                                    _prenomController.clear();
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white70,
                                                  ),
                                                )
                                              : null,
                                      filled: true,
                                      fillColor: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      focusedErrorBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Le prénom est obligatoire'
                                            : null,
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  // -------------------------------------------------
                                  // NOM
                                  // -------------------------------------------------
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Nom',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  TextFormField(
                                    controller: _nomController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Entrez votre nom',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                        color: Colors.white70,
                                      ),
                                      suffixIcon:
                                          _nomController.text.isNotEmpty
                                              ? IconButton(
                                                  onPressed: () {
                                                    _nomController.clear();
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white70,
                                                  ),
                                                )
                                              : null,
                                      filled: true,
                                      fillColor: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      focusedErrorBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Le nom est obligatoire'
                                            : null,
                                  ),

                                  const SizedBox(height: AppSpacing.xl),

                                  // -------------------------------------------------
                                  // BOUTON CONTINUER
                                  // -------------------------------------------------
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _continuer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Continuer',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}