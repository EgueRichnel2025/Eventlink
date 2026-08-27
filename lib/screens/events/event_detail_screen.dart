import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../widgets/error_retry_view.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _commentaireController = TextEditingController();
  EventModel? _event;
  bool _chargementEvent = true;
  String? _erreur;
  bool _envoiCommentaire = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargementEvent = true;
      _erreur = null;
    });

    // Tente d'abord de trouver l'event déjà en mémoire (liste déjà chargée).
    final events = context.read<EventProvider>();
    final existant = events.events.where((e) => e.id == widget.eventId).toList();
    if (existant.isNotEmpty) {
      _event = existant.first;
    }

    try {
      await events.chargerCommentaires(widget.eventId);
    } catch (_) {
      // Géré via errorMessage du provider si besoin, l'écran reste fonctionnel.
    }

    if (mounted) {
      setState(() => _chargementEvent = false);
    }
  }

  Future<void> _ouvrirLien() async {
    if (_event == null) return;
    final uri = Uri.tryParse(_event!.lien);
    if (uri == null) return;
    final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ouvert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce lien.')));
    }
  }

  Future<void> _envoyerCommentaire() async {
    final texte = _commentaireController.text.trim();
    if (texte.isEmpty) return;

    setState(() => _envoiCommentaire = true);
    final events = context.read<EventProvider>();
    final succes = await events.ajouterCommentaire(widget.eventId, texte);
    setState(() => _envoiCommentaire = false);

    if (succes) {
      _commentaireController.clear();
    } else if (mounted && events.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(events.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementEvent && _event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorRetryView(message: _erreur ?? 'Événement introuvable.', onRetry: _charger),
      );
    }

    final event = _event!;
    final dateFormatee = DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(event.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(title: Text(event.categorie.label)),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (event.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: Image.network(event.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(event.description, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: _ouvrirLien,
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.lien,
                              style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            event.auteur.prenom.isNotEmpty ? event.auteur.prenom[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.auteur.nomComplet, style: Theme.of(context).textTheme.titleMedium),
                              Text(dateFormatee, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 8,
                      children: StatutPersonnel.values.map((s) {
                        final selectionne = event.monStatut == s;
                        return ChoiceChip(
                          label: Text('${s.emoji} ${s.label}'),
                          selected: selectionne,
                          onSelected: (_) async {
                            await provider.changerStatut(event.id, s);
                            setState(() {
                              _event = event.copyWith(monStatut: s);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: AppSpacing.xl * 2),
                    Text('Commentaires', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    if (provider.chargementCommentaires)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.commentaires.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text(
                          'Aucun commentaire. Soyez le premier à réagir !',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    else
                      ...provider.commentaires.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(
                                    c.prenom.isNotEmpty ? c.prenom[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(c.nomComplet, style: Theme.of(context).textTheme.titleMedium),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormat('HH:mm', 'fr_FR').format(c.createdAt.toLocal()),
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(c.texte),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentaireController,
                          decoration: const InputDecoration(hintText: 'Ajouter un commentaire...'),
                          onSubmitted: (_) => _envoyerCommentaire(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: _envoiCommentaire ? null : _envoyerCommentaire,
                        icon: _envoiCommentaire
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
