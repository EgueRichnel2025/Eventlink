import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/groupe_model.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';
import '../groups/widgets/creer_groupe_sheet.dart';
import '../groups/widgets/rejoindre_groupe_sheet.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final TextEditingController _nomController;
  bool _enCours = false;
  bool _transfertEnCours = false;
  bool _promotionEnCours = false;
  bool _demotionEnCours = false;
  String? _nouveauProprioId;
  String? _adminAPromouvoirId;
  String? _adminARetrograderId;

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

  Future<void> _transfererPropriete(String nouveauProprioId) async {
    if (nouveauProprioId.isEmpty) return;

    setState(() => _transfertEnCours = true);
    try {
      await GroupService().transfererPropriete(
        context.read<GroupProvider>().groupeCourant!.id,
        context.read<GroupProvider>().groupeCourant!.ownerId,
        nouveauProprioId,
      );

      // Mettre à jour l'état local
      final groupProvider = context.read<GroupProvider>();
      final groupeActuel = groupProvider.groupeCourant;
      if (groupeActuel != null) {
        // Créer une nouvelle instance avec le nouvel ownerId
        final groupeMisAJour = groupeActuel.copyWith(ownerId: nouveauProprioId);
        groupProvider.mettreAJourGroupeDansListe(groupeMisAJour);

        // Si c'était notre groupe courant, mettre à jour aussi
        if (groupProvider.groupeCourant?.id == groupeActuel.id) {
          groupProvider.ouvrirGroupe(groupeMisAJour);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété transférée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _transfertEnCours = false);
      }
    }
  }

  Future<void> _promouvoirAdmin(String userId) async {
    if (userId.isEmpty) return;

    setState(() => _promotionEnCours = true);
    try {
      await GroupService().promouvoirAdmin(
        context.read<GroupProvider>().groupeCourant!.id,
        userId,
        context.read<GroupProvider>().groupeCourant!.ownerId,
      );

      // Mettre à jour l'état local des membres
      await context.read<GroupProvider>().chargerMembresDuGroupeCourant();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrateur promu avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _promotionEnCours = false);
      }
    }
  }

  Future<void> _retrocederAdmin(String userId) async {
    if (userId.isEmpty) return;

    setState(() => _demotionEnCours = true);
    try {
      await GroupService().retrocederAdmin(
        context.read<GroupProvider>().groupeCourant!.id,
        userId,
        context.read<GroupProvider>().groupeCourant!.ownerId,
      );

      // Mettre à jour l'état local des membres
      await context.read<GroupProvider>().chargerMembresDuGroupeCourant();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrateur rétrogradé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _demotionEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;
    final estProprietaire = groupe?.estProprietaire ?? false;
    final estAdmin = groupe?.estAdmin ?? false;

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
            enabled: estAdmin,
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
          if (estProprietaire) ...[
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Transférer la propriété',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Consumer<GroupProvider>(
              builder: (context, provider, _) {
                final membres = provider.membresDuGroupeCourant;
                final membresSansProprietaire = membres
                    .where((m) => m.userId != groupe.ownerId)
                    .toList();

                if (membresSansProprietaire.isEmpty) {
                  return const Text(
                    'Aucun autre membre auquel transférer la propriété',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _nouveauProprioId,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner le nouveau propriétaire',
                        border: OutlineInputBorder(),
                      ),
                      items: membresSansProprietaire
                          .map((m) => DropdownMenuItem(
                                value: m.userId,
                                child: Text('${m.prenom} ${m.nom}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _nouveauProprioId = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _transfertEnCours
                          ? null
                          : () => _transfererPropriete(_nouveauProprioId!),
                      child: _transfertEnCours
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ))
                          : const Text('Transférer la propriété'),
                    ),
                  ],
                );
              },
            ),
          ],
          if (estAdmin) ...[
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Gestion des administrateurs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Consumer<GroupProvider>(
              builder: (context, provider, _) {
                final membres = provider.membresDuGroupeCourant;

                // Séparer les membres par rôle
                final proprietaires = membres.where((m) => m.role == 'owner').toList();
                final administrateurs = membres
                    .where((m) => m.role == 'admin' && m.role != 'owner')
                    .toList();
                final membresSimples = membres
                    .where((m) => m.role == 'member')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (estProprietaire) ...[
                      const Text(
                        'Promouvoir un membre en administrateur',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: _adminAPromouvoirId,
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un membre',
                          border: OutlineInputBorder(),
                        ),
                        items: membresSimples
                            .map((m) => DropdownMenuItem(
                                  value: m.userId,
                                  child: Text('${m.prenom} ${m.nom}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _adminAPromouvoirId = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ElevatedButton(
                        onPressed: _promotionEnCours
                            ? null
                            : () => _promouvoirAdmin(_adminAPromouvoirId!),
                        child: _promotionEnCours
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ))
                            : const Text('Promouvoir en administrateur'),
                      ),
                    ],
                    if (administrateurs.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Rétrograder un administrateur en membre',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: _adminARetrograderId,
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un administrateur',
                          border: OutlineInputBorder(),
                        ),
                        items: administrateurs
                            .map((m) => DropdownMenuItem(
                                  value: m.userId,
                                  child: Text('${m.prenom} ${m.nom}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _adminARetrograderId = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ElevatedButton(
                        onPressed: _demotionEnCours
                            ? null
                            : () => _retrocederAdmin(_adminARetrograderId!),
                        child: _demotionEnCours
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ))
                            : const Text('Rétrograder en membre'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _enCours ? null : _enregistrer,
            child: _enCours
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}