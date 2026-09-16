import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationPasswordController =
      TextEditingController();

  final _scrollController = ScrollController();
  final _formFieldsKey = GlobalKey();

  String? _selectedAvatarId;
  bool _useInitials = false;
  bool _showAvatarGrid = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmationPassword = true;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final notifications = context.read<NotificationProvider>();

    setState(() => _isLoading = true);

    final succes = await auth.creerProfil(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      avatarId: _useInitials ? null : _selectedAvatarId,
    );

    if (!mounted) return;

    if (succes) {
      // Le profil vient d'être créé :
      // le JWT est maintenant disponible.
      // On peut donc enregistrer le token FCM auprès du backend.
      await notifications.enregistrerTokenApresConnexion();

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.groupeChoice,
      );
    } else {
      setState(() => _isLoading = false);

      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
          ),
        );
      }
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

  Widget _buildLabel(
    BuildContext context,
    String text,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isSmallScreen = size.width < 360;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

    final iconContainerSize =
        size.width < 360 ? 68.0 : 80.0;

    final iconSize =
        size.width < 360 ? 30.0 : 36.0;

    final titleSize =
        size.width < 360 ? 23.0 : 28.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics:
                        const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      size.height < 650 ? 16 : AppSpacing.lg,
                      horizontalPadding,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 700,
                          minHeight:
                              constraints.maxHeight -
                                  (size.height < 650
                                      ? 40
                                      : AppSpacing.lg * 2),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: iconContainerSize,
                                height: iconContainerSize,
                                decoration: BoxDecoration(
                                  gradient:
                                      const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset:
                                          const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.lg,
                              ),
                              Text(
                                'Faisons connaissance',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: titleSize,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: AppSpacing.sm,
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 700,
                                ),
                                child: Text(
                                  'Ces informations identifieront vos événements et vos commentaires auprès des autres membres.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.xl,
                              ),
                              Align(
                                alignment:
                                    Alignment.centerLeft,
                                child: Text(
                                  'Photo de profil',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.md,
                              ),
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
                                    InkWell(
                                      onTap:
                                          _choisirAvatar,
                                      borderRadius:
                                          BorderRadius.circular(
                                        16,
                                      ),
                                      child:
                                          AnimatedContainer(
                                        duration:
                                            const Duration(
                                          milliseconds: 200,
                                        ),
                                        width:
                                            double.infinity,
                                        padding:
                                            const EdgeInsets
                                                .all(16),
                                        decoration:
                                            BoxDecoration(
                                          color: !_useInitials
                                              ? AppColors
                                                  .primary
                                                  .withValues(
                                                  alpha: 0.18,
                                                )
                                              : Colors.white
                                                  .withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            16,
                                          ),
                                          border:
                                              Border.all(
                                            color: !_useInitials
                                                ? AppColors
                                                    .primary
                                                : Colors.white
                                                    .withValues(
                                                    alpha: 0.25,
                                                  ),
                                            width: !_useInitials
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration:
                                                  BoxDecoration(
                                                color: AppColors
                                                    .primary
                                                    .withValues(
                                                  alpha: 0.18,
                                                ),
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                              child:
                                                  const Icon(
                                                Icons
                                                    .face_rounded,
                                                color:
                                                    Colors.white,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 14,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'Choisir un avatar pour la photo de profil',
                                                    style: Theme.of(
                                                      context,
                                                    )
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: Colors
                                                              .white,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    height: 4,
                                                  ),
                                                  Text(
                                                    'Sélectionnez l’un des avatars proposés.',
                                                    style: Theme.of(
                                                      context,
                                                    )
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors
                                                              .white
                                                              .withValues(
                                                            alpha:
                                                                0.75,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Radio<bool>(
                                              value: false,
                                              activeColor:
                                                  AppColors
                                                      .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedSize(
                                      duration:
                                          const Duration(
                                        milliseconds: 350,
                                      ),
                                      curve:
                                          Curves.easeInOut,
                                      child: _showAvatarGrid
                                          ? Column(
                                              children: [
                                                const SizedBox(
                                                  height:
                                                      AppSpacing
                                                          .md,
                                                ),
                                                LayoutBuilder(
                                                  builder: (
                                                    context,
                                                    gridConstraints,
                                                  ) {
                                                    final width =
                                                        gridConstraints
                                                            .maxWidth;

                                                    int
                                                        crossAxisCount;

                                                    if (width >=
                                                        1200) {
                                                      crossAxisCount =
                                                          6;
                                                    } else if (width >=
                                                        900) {
                                                      crossAxisCount =
                                                          5;
                                                    } else if (width >=
                                                        600) {
                                                      crossAxisCount =
                                                          4;
                                                    } else if (width >=
                                                        400) {
                                                      crossAxisCount =
                                                          3;
                                                    } else {
                                                      crossAxisCount =
                                                          2;
                                                    }

                                                    return GridView
                                                        .builder(
                                                      shrinkWrap:
                                                          true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount:
                                                            crossAxisCount,
                                                        crossAxisSpacing:
                                                            10,
                                                        mainAxisSpacing:
                                                            10,
                                                        childAspectRatio:
                                                            1,
                                                      ),
                                                      itemCount:
                                                          66,
                                                      itemBuilder:
                                                          (
                                                        context,
                                                        index,
                                                      ) {
                                                        final avatarNumber =
                                                            index +
                                                                1;

                                                        final avatarId =
                                                            'avatar_${avatarNumber.toString().padLeft(2, '0')}';

                                                        final isSelected =
                                                            avatarId ==
                                                                _selectedAvatarId;

                                                        return GestureDetector(
                                                          onTap:
                                                              () {
                                                            _selectionnerAvatar(
                                                              avatarId,
                                                            );
                                                          },
                                                          child:
                                                              AnimatedContainer(
                                                            duration:
                                                                const Duration(
                                                              milliseconds:
                                                                  180,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                              3,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              border:
                                                                  Border.all(
                                                                color: isSelected
                                                                    ? AppColors.primary
                                                                    : Colors.transparent,
                                                                width:
                                                                    3,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                14,
                                                              ),
                                                              color: isSelected
                                                                  ? AppColors.primarySurface
                                                                  : Colors.white.withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                              boxShadow:
                                                                  isSelected
                                                                      ? [
                                                                          BoxShadow(
                                                                            color: AppColors.primary.withValues(
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
                                                            child:
                                                                Stack(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                                  child:
                                                                      SizedBox.expand(
                                                                    child:
                                                                        Image.asset(
                                                                      'assets/images/avatars/$avatarId.jpeg',
                                                                      fit:
                                                                          BoxFit.cover,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (isSelected)
                                                                  Positioned(
                                                                    bottom:
                                                                        6,
                                                                    right:
                                                                        6,
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          26,
                                                                      height:
                                                                          26,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color:
                                                                            AppColors.primary,
                                                                        shape:
                                                                            BoxShape.circle,
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              Colors.white,
                                                                          width:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          const Icon(
                                                                        Icons.check,
                                                                        size:
                                                                            16,
                                                                        color:
                                                                            Colors.white,
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
                                                  height:
                                                      AppSpacing
                                                          .lg,
                                                ),
                                              ],
                                            )
                                          : const SizedBox
                                              .shrink(),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white
                                                .withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Text(
                                            'OU',
                                            style: TextStyle(
                                              color: Colors
                                                  .white
                                                  .withValues(
                                                alpha: 0.75,
                                              ),
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white
                                                .withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
                                    ),
                                    InkWell(
                                      onTap:
                                          _choisirInitiales,
                                      borderRadius:
                                          BorderRadius.circular(
                                        16,
                                      ),
                                      child:
                                          AnimatedContainer(
                                        duration:
                                            const Duration(
                                          milliseconds: 200,
                                        ),
                                        width:
                                            double.infinity,
                                        padding:
                                            const EdgeInsets
                                                .all(16),
                                        decoration:
                                            BoxDecoration(
                                          color: _useInitials
                                              ? AppColors
                                                  .primary
                                                  .withValues(
                                                  alpha: 0.18,
                                                )
                                              : Colors.white
                                                  .withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            16,
                                          ),
                                          border:
                                              Border.all(
                                            color: _useInitials
                                                ? AppColors
                                                    .primary
                                                : Colors.white
                                                    .withValues(
                                                    alpha: 0.25,
                                                  ),
                                            width: _useInitials
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration:
                                                  BoxDecoration(
                                                color: AppColors
                                                    .primary
                                                    .withValues(
                                                  alpha: 0.18,
                                                ),
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                              child:
                                                  const Icon(
                                                Icons
                                                    .text_fields_rounded,
                                                color:
                                                    Colors.white,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 14,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'Choisir mes initiales pour la photo de profil',
                                                    style: Theme.of(
                                                      context,
                                                    )
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: Colors
                                                              .white,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    height: 4,
                                                  ),
                                                  Text(
                                                    'Vos initiales seront utilisées comme photo de profil.',
                                                    style: Theme.of(
                                                      context,
                                                    )
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors
                                                              .white
                                                              .withValues(
                                                            alpha:
                                                                0.75,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Radio<bool>(
                                              value: true,
                                              activeColor:
                                                  AppColors
                                                      .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.xl,
                              ),
                              Container(
                                key: _formFieldsKey,
                                child: Column(
                                  children: [
                                    _buildLabel(
                                      context,
                                      'Prénom',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _prenomController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction:
                                          TextInputAction.next,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                        hintText:
                                            'Entrez votre prénom',
                                        prefixIcon: Icons
                                            .person_outline_rounded,
                                        suffixIcon:
                                            _prenomController
                                                    .text
                                                    .isNotEmpty
                                                ? IconButton(
                                                    onPressed:
                                                        () {
                                                      _prenomController
                                                          .clear();
                                                      setState(
                                                        () {},
                                                      );
                                                    },
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .clear_rounded,
                                                      color: Colors
                                                          .white70,
                                                    ),
                                                  )
                                                : null,
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                      validator: (v) =>
                                          (v == null ||
                                                  v.trim()
                                                      .isEmpty)
                                              ? 'Le prénom est obligatoire'
                                              : null,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
                                    ),
                                    _buildLabel(
                                      context,
                                      'Nom',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _nomController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction:
                                          TextInputAction.next,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                        hintText:
                                            'Entrez votre nom',
                                        prefixIcon: Icons
                                            .badge_outlined,
                                        suffixIcon:
                                            _nomController
                                                    .text
                                                    .isNotEmpty
                                                ? IconButton(
                                                    onPressed:
                                                        () {
                                                      _nomController
                                                          .clear();
                                                      setState(
                                                        () {},
                                                      );
                                                    },
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .clear_rounded,
                                                      color: Colors
                                                          .white70,
                                                    ),
                                                  )
                                                : null,
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                      validator: (v) =>
                                          (v == null ||
                                                  v.trim()
                                                      .isEmpty)
                                              ? 'Le nom est obligatoire'
                                              : null,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
                                    ),
                                    _buildLabel(
                                      context,
                                      'Adresse e-mail',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _emailController,
                                      keyboardType:
                                          TextInputType
                                              .emailAddress,
                                      textInputAction:
                                          TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                        hintText:
                                            'Entrez votre adresse e-mail',
                                        prefixIcon: Icons
                                            .email_outlined,
                                        suffixIcon:
                                            _emailController
                                                    .text
                                                    .isNotEmpty
                                                ? IconButton(
                                                    onPressed:
                                                        () {
                                                      _emailController
                                                          .clear();
                                                      setState(
                                                        () {},
                                                      );
                                                    },
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .clear_rounded,
                                                      color: Colors
                                                          .white70,
                                                    ),
                                                  )
                                                : null,
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                      validator: (v) {
                                        final email =
                                            v?.trim() ?? '';

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
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
                                    ),
                                    _buildLabel(
                                      context,
                                      'Mot de passe',
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
                                        AutofillHints
                                            .newPassword,
                                      ],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                        hintText:
                                            'Minimum 8 caractères',
                                        prefixIcon: Icons
                                            .lock_outline_rounded,
                                        suffixIcon:
                                            IconButton(
                                          onPressed: () {
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
                                            color:
                                                Colors.white70,
                                          ),
                                        ),
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                      validator: (v) {
                                        final password =
                                            v ?? '';

                                        if (password.isEmpty) {
                                          return 'Le mot de passe est obligatoire';
                                        }

                                        if (password.length < 8) {
                                          return 'Le mot de passe doit contenir au moins 8 caractères';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
                                    ),
                                    _buildLabel(
                                      context,
                                      'Confirmer le mot de passe',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _confirmationPasswordController,
                                      obscureText:
                                          _obscureConfirmationPassword,
                                      textInputAction:
                                          TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints
                                            .newPassword,
                                      ],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                        hintText:
                                            'Retapez votre mot de passe',
                                        prefixIcon: Icons
                                            .lock_reset_rounded,
                                        suffixIcon:
                                            IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmationPassword =
                                                  !_obscureConfirmationPassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureConfirmationPassword
                                                ? Icons
                                                    .visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            color:
                                                Colors.white70,
                                          ),
                                        ),
                                      ),
                                      onFieldSubmitted:
                                          _isLoading
                                              ? null
                                              : (_) =>
                                                  _continuer(),
                                      validator: (v) {
                                        final confirmation =
                                            v ?? '';

                                        if (confirmation
                                            .isEmpty) {
                                          return 'Veuillez confirmer votre mot de passe';
                                        }

                                        if (confirmation !=
                                            _passwordController
                                                .text) {
                                          return 'Les mots de passe ne correspondent pas';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.xl,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child:
                                          ElevatedButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : _continuer,
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                              AppColors
                                                  .primary,
                                          foregroundColor:
                                              Colors.white,
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                AppSpacing.md,
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
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors
                                                      .white,
                                                ),
                                              )
                                            : const Text(
                                                'Continuer',
                                                style:
                                                    TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.md,
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

            // Bouton retour vers « Choisir un compte »
            //
            // IMPORTANT :
            // Il est volontairement placé EN DERNIER dans le Stack.
            // Il se trouve ainsi au-dessus du SingleChildScrollView
            // et reçoit correctement les clics.
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    top: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                      color: Colors.white,
                      tooltip: 'Retour',
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