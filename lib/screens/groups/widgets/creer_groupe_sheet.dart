import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/group_provider.dart';

class CreerGroupeSheet extends StatefulWidget {
  const CreerGroupeSheet({super.key});

  @override
  State<CreerGroupeSheet> createState() => _CreerGroupeSheetState();
}

class _CreerGroupeSheetState extends State<CreerGroupeSheet> {
  final _nomController = TextEditingController();
  bool _enCours = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    setState(() => _errorMessage = null);

    final nom = _nomController.text.trim();

    if (nom.isEmpty) {
      setState(
        () => _errorMessage = 'Le nom du groupe est obligatoire',
      );
      return;
    }

    setState(() => _enCours = true);

    final groupes = context.read<GroupProvider>();
    final groupe = await groupes.creerGroupe(nom);

    if (!mounted) return;

    setState(() => _enCours = false);

    if (groupe == null) {
      setState(
        () => _errorMessage =
            groupes.errorMessage ??
            'Erreur lors de la création du groupe',
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupeCreeDialog(
        code: groupe.codeInvitation,
        nomGroupe: groupe.nom,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardHeight,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Créer un groupe',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choisissez un nom clair pour votre communauté.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _nomController,
                  autofocus: true,
                  enabled: !_enCours,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    hintText: 'Ex : Groupe GOHOMANJIKAI',
                    labelStyle:  TextStyle(
                      color: Colors.black54,
                    ),
                    hintStyle:  TextStyle(
                      color: Colors.black38,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:  BorderRadius.all(
                        Radius.circular(AppRadius.button),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.button),
                      ),
                      borderSide:  BorderSide(
                        color: AppColors.divider,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.button),
                      ),
                      borderSide:  BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _creer(),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_errorMessage != null)
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _enCours ? null : _creer,
                  child: _enCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupeCreeDialog extends StatelessWidget {
  final String code;
  final String nomGroupe;

  const _GroupeCreeDialog({
    required this.code,
    required this.nomGroupe,
  });

  Future<void> _copier(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copié !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Groupe créé !',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Partagez ce code avec vos amis pour qu\'ils puissent rejoindre "$nomGroupe".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () => _copier(context),
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.copy_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}