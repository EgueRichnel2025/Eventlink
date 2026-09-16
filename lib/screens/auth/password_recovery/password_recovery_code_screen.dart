import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class PasswordRecoveryCodeScreen
    extends StatefulWidget {
  final String email;

  const PasswordRecoveryCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordRecoveryCodeScreen> createState() =>
      _PasswordRecoveryCodeScreenState();
}

class _PasswordRecoveryCodeScreenState
    extends State<PasswordRecoveryCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifierCode() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final resetToken =
        await auth.verifierCodeRecuperation(
      email: widget.email,
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    if (resetToken == null) {
      final message = auth.errorMessage ??
          'Le code de récupération est invalide.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.passwordRecoveryNewPassword,
      arguments: resetToken,
    );
  }

  Future<void> _renvoyerCode() async {
    final auth = context.read<AuthProvider>();

    final succes =
        await auth.demanderCodeRecuperation(
      widget.email,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succes
              ? 'Un nouveau code a été envoyé à votre adresse e-mail.'
              : auth.errorMessage ??
                  'Impossible de renvoyer le code.',
        ),
      ),
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
          'Vérification',
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
                  children: [
                    Container(
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
                            .mark_email_read_rounded,
                        color:
                            AppColors.primary,
                        size:
                            isSmallScreen ? 34 : 40,
                      ),
                    ),
                    SizedBox(
                      height:
                          size.height < 650
                              ? 20
                              : 28,
                    ),
                    Text(
                      'Entrez votre code',
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
                    const SizedBox(height: 10),
                    const Text(
                      'Un code à 6 chiffres a été envoyé à',
                      textAlign:
                          TextAlign.center,
                      style:  TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.email,
                      textAlign:
                          TextAlign.center,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      height:
                          size.height < 650
                              ? 28
                              : 40,
                    ),
                    TextFormField(
                      controller:
                          _codeController,
                      focusNode: _focusNode,
                      keyboardType:
                          TextInputType.number,
                      textInputAction:
                          TextInputAction.done,
                      textAlign: TextAlign.center,
                      enabled: !auth.isLoading,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                      style: TextStyle(
                        fontSize:
                            isSmallScreen
                                ? 28
                                : 32,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 8,
                        color:
                            AppColors.textPrimary,
                      ),
                      decoration:
                         const InputDecoration(
                        hintText: '000000',
                        counterText: '',
                        prefixIcon:  Icon(
                          Icons
                              .pin_outlined,
                        ),
                      ),
                      validator: (value) {
                        final code =
                            value?.trim() ?? '';

                        if (code.length != 6) {
                          return 'Entrez le code à 6 chiffres reçu par e-mail';
                        }

                        return null;
                      },
                      onChanged: (value) {
                        if (value.length == 6) {
                          _verifierCode();
                        }
                      },
                      onFieldSubmitted:
                          auth.isLoading
                              ? null
                              : (_) =>
                                  _verifierCode(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            auth.isLoading
                                ? null
                                : _verifierCode,
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
                                    .verified_outlined,
                              ),
                        label: Text(
                          auth.isLoading
                              ? 'Vérification...'
                              : 'Vérifier le code',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed:
                          auth.isLoading
                              ? null
                              : _renvoyerCode,
                      icon: const Icon(
                        Icons
                            .refresh_rounded,
                      ),
                      label: const Text(
                        'Renvoyer le code',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
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
                        'Modifier l’adresse e-mail',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                .schedule_outlined,
                            color:
                                AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Le code de récupération est temporaire. Si vous ne le recevez pas, vérifiez également vos courriers indésirables.',
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