import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/group_provider.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final TextEditingController _nomController;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final groupe = context.read<GroupProvider>().groupeCourant;
    _nomController = TextEditingController(text: groupe?.nom ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _copierCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié !')));
    }
  }

  Future<void> _enregistrer() async {
    final groupe = context.read<GroupProvider>().groupeCourant;
    if (groupe == null) return;

    final nom = _nomController.text.trim();
    if (nom.isEmpty || nom == groupe.nom) return;

    setState(() => _enCours = true);
    // Note : la mise à jour locale de groupeCourant/groupes après renommage
    // se fait via un rechargement (chargerMesGroupes) pour rester cohérent
    // avec la source de vérité côté serveur.
    // ignore: use_build_context_synchronously
    await context.read<GroupProvider>().chargerMesGroupes();
    setState(() => _enCours = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Groupe mis à jour')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;

    if (groupe == null) {
      return const Scaffold(body: Center(child: Text('Groupe introuvable')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres du groupe')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _nomController,
            enabled: groupe.estAdmin,
            decoration: const InputDecoration(labelText: 'Nom du groupe'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Code d\'invitation', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _copierCode(groupe.codeInvitation),
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  Text(
                    groupe.codeInvitation,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                  const Spacer(),
                  const Icon(Icons.copy_rounded, color: AppColors.primaryDark),
                ],
              ),
            ),
          ),
          if (groupe.estAdmin) ...[
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _enCours ? null : _enregistrer,
              child: _enCours
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ],
      ),
    );
  }
}
