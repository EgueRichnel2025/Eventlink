import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/group_provider.dart';

class RejoindreGroupeSheet extends StatefulWidget {
  const RejoindreGroupeSheet({super.key});

  @override
  State<RejoindreGroupeSheet> createState() =>
      _RejoindreGroupeSheetState();
}

class _RejoindreGroupeSheetState
    extends State<RejoindreGroupeSheet> {
  final _codeController = TextEditingController();
  bool _enCours = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _rejoindre() async {
    setState(() => _errorMessage = null);

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(
        () => _errorMessage =
            'Le code d\'invitation est obligatoire',
      );
      return;
    }

    setState(() => _enCours = true);

    final groupes = context.read<GroupProvider>();
    final groupe = await groupes.rejoindreGroupe(code);

    if (!mounted) return;

    setState(() => _enCours = false);

    if (groupe == null) {
      setState(
        () => _errorMessage =
            groupes.errorMessage ??
            'Code d\'invitation invalide',
      );
      return;
    }

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
                  'Rejoindre un groupe',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Entrez le code d\'invitation partagé par un membre.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  enabled: !_enCours,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Code d\'invitation',
                    hintText: 'Ex : ABC123',
                    labelStyle:  TextStyle(
                      color: Colors.black54,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.black38,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
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
                  onSubmitted: (_) => _rejoindre(),
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
                  onPressed: _enCours ? null : _rejoindre,
                  child: _enCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Rejoindre'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}