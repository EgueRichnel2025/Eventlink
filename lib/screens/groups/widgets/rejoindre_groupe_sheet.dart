import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../providers/group_provider.dart';

class RejoindreGroupeSheet extends StatefulWidget {
  const RejoindreGroupeSheet({super.key});

  @override
  State<RejoindreGroupeSheet> createState() => _RejoindreGroupeSheetState();
}

class _RejoindreGroupeSheetState extends State<RejoindreGroupeSheet> {
  final _codeController = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _rejoindre() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _enCours = true);
    final groupes = context.read<GroupProvider>();
    final groupe = await groupes.rejoindreGroupe(code);
    setState(() => _enCours = false);

    if (!mounted) return;

    if (groupe == null) {
      if (groupes.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(groupes.errorMessage!)));
      }
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Rejoindre un groupe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Entrez le code d\'invitation partagé par un membre.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code d\'invitation', hintText: 'Ex : ABC123'),
              onSubmitted: (_) => _rejoindre(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _enCours ? null : _rejoindre,
              child: _enCours
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
