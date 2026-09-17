import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/comment_model.dart';
import '../../models/event_model.dart';
import '../../models/groupe_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/error_retry_view.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() =>
      _EventDetailScreenState();
}

class _EventDetailScreenState
    extends State<EventDetailScreen> {
  final _commentaireController =
      TextEditingController();

  EventModel? _event;
  bool _chargementEvent = true;
  String? _erreur;
  bool _envoiCommentaire = false;
  bool _suppressionEnCours = false;

  CommentModel? _commentaireEnReponse;

  bool _afficherSuggestionsMention = false;
  String _rechercheMention = '';
  int _positionDebutMention = -1;
  final Map<String, MembreGroupeModel> _mentionsSelectionnees = {};

  static const List<String> _reactionsDisponibles = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  @override
  void initState() {
    super.initState();
    _commentaireController.addListener(_gererSaisieMention);
    _charger();
  }

  @override
  void dispose() {
    _commentaireController.removeListener(_gererSaisieMention);
    _commentaireController.dispose();
    super.dispose();
  }

  void _gererSaisieMention() {
    final texte = _commentaireController.text;
    final position = _commentaireController.selection.baseOffset;

    if (position < 0 || position > texte.length) return;

    final avantCurseur = texte.substring(0, position);
    final match = RegExp(r'@([A-Za-zÀ-ÿ0-9_-]*)$').firstMatch(avantCurseur);

    if (match == null) {
      if (_afficherSuggestionsMention && mounted) {
        setState(() {
          _afficherSuggestionsMention = false;
          _rechercheMention = '';
          _positionDebutMention = -1;
        });
      }
      return;
    }

    final recherche = match.group(1) ?? '';
    final debutMention = match.start;

    if (!mounted) return;

    setState(() {
      _afficherSuggestionsMention = true;
      _rechercheMention = recherche;
      _positionDebutMention = debutMention;
    });

    final groupProvider = context.read<GroupProvider>();
    groupProvider.definirRechercheMembres(recherche);
    groupProvider.chargerMembresDuGroupeCourant(
      recherche: recherche,
    );
  }

  void _selectionnerMention(MembreGroupeModel membre) {
    final texte = _commentaireController.text;
    final position = _commentaireController.selection.baseOffset;

    if (_positionDebutMention < 0 ||
        position < _positionDebutMention ||
        position > texte.length) {
      return;
    }

    final nomMention = membre.prenom.isNotEmpty
        ? membre.prenom
        : membre.nom;

    final avant = texte.substring(0, _positionDebutMention);
    final apres = texte.substring(position);

    final insertion = '@$nomMention ';

    final nouveauTexte = '$avant$insertion$apres';
    final nouvellePosition =
        (avant + insertion).length;

    _commentaireController.value =
        TextEditingValue(
      text: nouveauTexte,
      selection: TextSelection.collapsed(
        offset: nouvellePosition,
      ),
    );

    setState(() {
      _mentionsSelectionnees[membre.userId] = membre;
      _afficherSuggestionsMention = false;
      _rechercheMention = '';
      _positionDebutMention = -1;
    });
  }

  Future<void> _charger() async {
    setState(() {
      _chargementEvent = true;
      _erreur = null;
    });

    // Tente d'abord de trouver l'event déjà en mémoire (liste déjà chargée).
    final events = context.read<EventProvider>();

    final existant = events.events
        .where((e) => e.id == widget.eventId)
        .toList();

    if (existant.isNotEmpty) {
      _event = existant.first;
    }

    try {
      final eventCharge =
          await events.obtenirEvent(widget.eventId);

      if (eventCharge != null) {
        _event = eventCharge;
      }

      await events.chargerCommentaires(
        widget.eventId,
      );
    } catch (_) {
      // Géré via errorMessage du provider si besoin,
      // l'écran reste fonctionnel avec l'événement déjà chargé.
    }

    if (mounted) {
      setState(() {
        _chargementEvent = false;
      });
    }
  }

  Future<void> _ouvrirLien() async {
    if (_event == null) return;

    final uri = Uri.tryParse(_event!.lien);

    if (uri == null) return;

    final ouvert = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ouvert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'ouvrir ce lien.',
          ),
        ),
      );
    }
  }

  Future<void> _envoyerCommentaire() async {
    final texte =
        _commentaireController.text.trim();

    if (texte.isEmpty) return;

    setState(() {
      _envoiCommentaire = true;
    });

    final events = context.read<EventProvider>();

    final mentions = _mentionsSelectionnees.values
        .where(
          (membre) => texte.contains('@${membre.prenom}'),
        )
        .map(
          (membre) => CommentMentionModel(
            userId: membre.userId,
          ),
        )
        .toList();

    final succes =
        await events.ajouterCommentaire(
      widget.eventId,
      texte,
      parentCommentId:
          _commentaireEnReponse?.id,
      mentions: mentions,
    );

    if (!mounted) return;

    setState(() {
      _envoiCommentaire = false;
    });

    if (succes) {
      _commentaireController.clear();

      setState(() {
        _commentaireEnReponse = null;
        _mentionsSelectionnees.clear();
        _afficherSuggestionsMention = false;
        _rechercheMention = '';
        _positionDebutMention = -1;
      });
    } else if (events.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            events.errorMessage!,
          ),
        ),
      );
    }
  }

  Widget _construireSuggestionsMention() {
    final groupProvider = context.watch<GroupProvider>();
    final membres = groupProvider.membresDuGroupeCourant;

    final terme = _rechercheMention.trim().toLowerCase();
    final membresFiltres = terme.isEmpty
        ? membres
        : membres.where((membre) {
            final prenom = membre.prenom.toLowerCase();
            final nom = membre.nom.toLowerCase();
            return prenom.contains(terme) ||
                nom.contains(terme);
          }).toList();

    if (membresFiltres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 220,
      ),
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -3),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        itemCount: membresFiltres.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.10),
        ),
        itemBuilder: (context, index) {
          final membre = membresFiltres[index];

          return ListTile(
            dense: true,
            leading: _avatarMembreMention(membre),
            title: Text(
              membre.nomComplet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '@${membre.prenom}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: () => _selectionnerMention(membre),
          );
        },
      ),
    );
  }

  Widget _avatarMembreMention(MembreGroupeModel membre) {
    if (membre.avatarId != null &&
        membre.avatarId!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: AssetImage(
          'assets/images/avatars/${membre.avatarId}.jpeg',
        ),
      );
    }

    if (membre.photoUrl != null &&
        membre.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: NetworkImage(
          membre.photoUrl!,
        ),
      );
    }

    final initiales = '${membre.prenom.isNotEmpty ? membre.prenom[0] : ''}'
        '${membre.nom.isNotEmpty ? membre.nom[0] : ''}'
        .toUpperCase();

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        initiales,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }


  Widget _avatarAuteur(EventModel event) {
    if (event.auteur.avatarId != null &&
        event.auteur.avatarId!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: AssetImage(
          'assets/images/avatars/${event.auteur.avatarId}.jpeg',
        ),
        onBackgroundImageError: (_, __) {},
      );
    }

    if (event.auteur.photoUrl != null &&
        event.auteur.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(
          event.auteur.photoUrl!,
        ),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor:
          AppColors.primarySurface,
      child: Text(
        event.auteur.prenom.isNotEmpty
            ? event.auteur.prenom[0]
                .toUpperCase()
            : '?',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }

  Future<void> _repondreAuCommentaire(
    CommentModel commentaire,
  ) async {
    setState(() {
      _commentaireEnReponse = commentaire;
    });
  }

  Future<void> _copierCommentaire(
    CommentModel commentaire,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: commentaire.texte,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Commentaire copié.',
        ),
      ),
    );
  }

  Future<void> _epinglerCommentaire(
    CommentModel commentaire,
  ) async {
    final provider =
        context.read<EventProvider>();

    final succes =
        await provider.toggleCommentEpingle(
      eventId: widget.eventId,
      commentId: commentaire.id,
    );

    if (!mounted) return;

    if (!succes &&
        provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
          ),
        ),
      );
    }
  }

  Future<void> _modifierCommentaire(
    CommentModel commentaire,
  ) async {
    final controller = TextEditingController(
      text: commentaire.texte,
    );

    final texte = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Modifier le commentaire',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 500,
            maxLines: 5,
            minLines: 2,
            autofocus: true,
            textCapitalization:
                TextCapitalization.sentences,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Votre commentaire...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.of(dialogContext)
                    .pop(value);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || texte == null) {
      return;
    }

    final provider =
        context.read<EventProvider>();

    final succes =
        await provider.modifierCommentaire(
      eventId: widget.eventId,
      commentId: commentaire.id,
      texte: texte,
    );

    if (!mounted) return;

    if (!succes &&
        provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
          ),
        ),
      );
    }
  }

  Future<void> _supprimerCommentaire(
    CommentModel commentaire,
  ) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Supprimer le commentaire ?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Cette action est définitive.',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) {
      return;
    }

    final provider =
        context.read<EventProvider>();

    final succes =
        await provider.supprimerCommentaire(
      eventId: widget.eventId,
      commentId: commentaire.id,
    );

    if (!mounted) return;

    if (!succes &&
        provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
          ),
        ),
      );
    }
  }

  Future<void> _afficherActionsCommentaire(
    CommentModel commentaire,
  ) async {
    final authProvider =
        context.read<AuthProvider>();

    final groupProvider =
        context.read<GroupProvider>();

    final userId =
        authProvider.currentUser?.id;

    final estAuteur =
        userId != null &&
        commentaire.userId == userId;

    final estAdmin =
        groupProvider.groupeCourant?.estAdmin ??
            false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text(
                  '📋',
                  style: TextStyle(fontSize: 22),
                ),
                title: const Text(
                  'Copier',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _copierCommentaire(
                    commentaire,
                  );
                },
              ),
              ListTile(
                leading: const Text(
                  '↩️',
                  style: TextStyle(fontSize: 22),
                ),
                title: const Text(
                  'Répondre',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _repondreAuCommentaire(
                    commentaire,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_reaction_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Réagir',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _afficherPaletteReactions(
                    commentaire,
                  );
                },
              ),
              if (estAdmin)
                ListTile(
                  leading: const Text(
                    '📌',
                    style: TextStyle(fontSize: 22),
                  ),
                  title: Text(
                    commentaire.epingle
                        ? 'Désépingler'
                        : 'Épingler',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _epinglerCommentaire(
                      commentaire,
                    );
                  },
                ),
              if (estAuteur)
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Modifier',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _modifierCommentaire(
                      commentaire,
                    );
                  },
                ),
              if (estAuteur || estAdmin)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Supprimer',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _supprimerCommentaire(
                      commentaire,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarCommentaire(
    dynamic commentaire,
  ) {
    if (commentaire.avatarId != null &&
        commentaire.avatarId!.isNotEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundImage: AssetImage(
          'assets/images/avatars/${commentaire.avatarId}.jpeg',
        ),
      );
    }

    if (commentaire.photoUrl != null &&
        commentaire.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundImage: NetworkImage(
          commentaire.photoUrl!,
        ),
      );
    }

    return CircleAvatar(
      radius: 21,
      backgroundColor:
          AppColors.primarySurface,
      child: Text(
        commentaire.prenom.isNotEmpty
            ? commentaire.prenom[0]
                .toUpperCase()
            : '?',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _afficherPaletteReactions(
    CommentModel commentaire,
  ) async {
    final provider =
        context.read<EventProvider>();

    final reaction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children:
                  _reactionsDisponibles.map((emoji) {
                final selectionne =
                    commentaire.userReaction ==
                        emoji;

                return Material(
                  color: selectionne
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context)
                          .pop(emoji);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: selectionne
                            ? Border.all(
                                color:
                                    AppColors.primary,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (reaction == null || !mounted) {
      return;
    }

    final succes =
        await provider.toggleCommentReaction(
      eventId: widget.eventId,
      commentId: commentaire.id,
      reactionType: reaction,
    );

    if (!succes &&
        mounted &&
        provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
          ),
        ),
      );
    }
  }

  Widget _reactionsCommentaire(
    CommentModel commentaire,
  ) {
    if (commentaire.reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final reactions = commentaire.reactions.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 4,
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: reactions.map((entry) {
          final estMaReaction =
              commentaire.userReaction ==
                  entry.key;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: estMaReaction
                  ? AppColors.primarySurface
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: estMaReaction
                    ? AppColors.primary
                    : Colors.grey.withValues(
                        alpha: 0.18,
                      ),
                width: estMaReaction ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: estMaReaction
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitre({
    required IconData icon,
    required String titre,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryDark,
            size: 19,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          titre,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _carteImage(EventModel event) {
    if (event.imageUrl == null ||
        event.imageUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            event.imageUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (
              context,
              child,
              loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }

              return Container(
                color: AppColors.surfaceMuted,
                child: const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: AppColors.surfaceMuted,
                child: const Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .image_not_supported_outlined,
                      size: 44,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image indisponible',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _carteAuteur(
    EventModel event,
    String dateFormatee,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Colors.grey
              .withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatarAuteur(event),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publié par',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.auteur.nomComplet,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Publié le $dateFormatee',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteLien(EventModel event) {
    return InkWell(
      onTap: _ouvrirLien,
      borderRadius:
          BorderRadius.circular(AppRadius.card),
      child: Container(
        padding:
            const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySurface
              .withValues(alpha: 0.55),
          borderRadius:
              BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.primary
                .withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 22,
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
                  const Text(
                    'Lien de l\'événement',
                    style: TextStyle(
                      color:
                          AppColors.textPrimary,
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event.lien,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          AppColors.primaryDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Text(
                        'Ouvrir le lien',
                        style: TextStyle(
                          color:
                              AppColors.primaryDark,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons
                            .arrow_forward_rounded,
                        color:
                            AppColors.primaryDark,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteStatistiques(
    EventModel event,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius:
            BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statistique(
              icon: Icons.visibility_outlined,
              valeur: '${event.vues}',
              label: 'vues',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: Colors.grey
                .withValues(alpha: 0.20),
          ),
          Expanded(
            child: _statistique(
              icon:
                  Icons.chat_bubble_outline_rounded,
              valeur:
                  '${event.nombreCommentaires}',
              label: 'commentaires',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statistique({
    required IconData icon,
    required String valeur,
    required String label,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              valeur,
              style: const TextStyle(
                color:
                    AppColors.textPrimary,
                fontWeight:
                    FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carteCommentaire(
    CommentModel commentaire,
  ) {
    final date = DateFormat(
      'dd/MM à HH:mm',
      'fr_FR',
    ).format(
      commentaire.createdAt.toLocal(),
    );

    final commentaires =
        context.read<EventProvider>().commentaires;

    CommentModel? parent;

    for (final element in commentaires) {
      if (element.id == commentaire.parentCommentId) {
        parent = element;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
      ),
      child: GestureDetector(
        onLongPress: () =>
            _afficherActionsCommentaire(
          commentaire,
        ),
        onHorizontalDragEnd: (details) {
          final velocity =
              details.primaryVelocity ?? 0;

          if (velocity > 250) {
            _repondreAuCommentaire(
              commentaire,
            );
          }
        },
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _avatarCommentaire(
              commentaire,
            ),
            const SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      AppSpacing.md,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.surfaceMuted,
                      borderRadius:
                          BorderRadius.only(
                        topRight:
                            Radius.circular(16),
                        bottomLeft:
                            Radius.circular(16),
                        bottomRight:
                            Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (parent != null) ...[
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(8),
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.65,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '↩️ ${parent.nomComplet}',
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.primaryDark,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  parent.texte,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                        ],
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (commentaire.epingle)
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(
                                        right: 5,
                                      ),
                                      child: Text(
                                        '📌',
                                        style:
                                            TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      commentaire.nomComplet,
                                      style:
                                          const TextStyle(
                                        color:
                                            AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              date,
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          commentaire.texte,
                          style:
                              const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _reactionsCommentaire(
                    commentaire,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _demanderRaisonSuppression(
    EventModel event,
  ) async {
    final controller = TextEditingController();

    final raison = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final raisonValide =
                controller.text.trim().isNotEmpty;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Supprimer l’événement ?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cet événement appartient à '
                      '${event.auteur.nomComplet}.',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Une raison est obligatoire. '
                      'Elle sera communiquée à l’auteur.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLength: 500,
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization:
                          TextCapitalization.sentences,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText:
                            'Raison de la suppression',
                        hintText:
                            'Expliquez pourquoi cet événement est supprimé...',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: raisonValide
                      ? () {
                          Navigator.of(dialogContext).pop(
                            controller.text.trim(),
                          );
                        }
                      : null,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text('Supprimer'),
                ),
              ],
            );
          },
        );
      },
    );

    return raison;
  }

  Future<void> _supprimerEvenement(
    EventModel event,
  ) async {
    if (_suppressionEnCours) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();
    final groupProvider =
        context.read<GroupProvider>();

    final userId =
        authProvider.currentUser?.id;

    final estAuteur =
        userId != null &&
        event.auteur.userId == userId;

    final groupe =
        groupProvider.groupeCourant;

    final estAdminOuProprietaire =
        groupe?.estAdmin ?? false;

    if (!estAuteur && !estAdminOuProprietaire) {
      return;
    }

    String? raison;

    if (estAuteur) {
      final confirmer = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Supprimer l’événement ?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true),
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text('Supprimer'),
              ),
            ],
          );
        },
      );

      if (confirmer != true || !mounted) {
        return;
      }
    } else {
      raison = await _demanderRaisonSuppression(event);

      if (raison == null ||
          raison.trim().isEmpty ||
          !mounted) {
        return;
      }
    }

    setState(() {
      _suppressionEnCours = true;
    });

    final provider =
        context.read<EventProvider>();

    final success =
        await provider.supprimerEvent(
      event.id,
      raison: raison,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _suppressionEnCours = false;
    });

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    final message =
        provider.errorMessage ??
        'Impossible de supprimer cet événement.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementEvent &&
        _event == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black
              .withValues(alpha: 0.12),
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: () =>
                Navigator.of(context)
                    .maybePop(),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    AppColors.primarySurface,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color:
                    AppColors.primaryDark,
                size: 21,
              ),
            ),
          ),
          title: const Text(
            'Événement',
            style: TextStyle(
              color:
                  AppColors.textPrimary,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black
              .withValues(alpha: 0.12),
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: () =>
                Navigator.of(context)
                    .maybePop(),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    AppColors.primarySurface,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color:
                    AppColors.primaryDark,
                size: 21,
              ),
            ),
          ),
          title: const Text(
            'Événement',
            style: TextStyle(
              color:
                  AppColors.textPrimary,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        body: ErrorRetryView(
          message: _erreur ??
              'Événement introuvable.',
          onRetry: _charger,
        ),
      );
    }

    final event = _event!;

    final dateFormatee = DateFormat(
      'd MMMM yyyy à HH:mm',
      'fr_FR',
    ).format(
      event.createdAt.toLocal(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 2,
        shadowColor: Colors.black
            .withValues(alpha: 0.12),
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 2,
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () =>
              Navigator.of(context)
                  .maybePop(),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  AppColors.primarySurface,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color:
                  AppColors.primaryDark,
              size: 22,
            ),
          ),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.categorie.label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: (() {
          final authProvider =
              context.read<AuthProvider>();
          final groupProvider =
              context.read<GroupProvider>();

          final userId =
              authProvider.currentUser?.id;

          final estAuteur =
              userId != null &&
              event.auteur.userId == userId;

          final estAdminOuProprietaire =
              groupProvider.groupeCourant?.estAdmin ??
                  false;

          final peutSupprimer =
              estAuteur ||
              estAdminOuProprietaire;

          if (!peutSupprimer) {
            return <Widget>[];
          }

          return [
            PopupMenuButton<String>(
              tooltip: 'Actions',
              enabled: !_suppressionEnCours,
              onSelected: (value) {
                if (value == 'supprimer') {
                  _supprimerEvenement(event);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'supprimer',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color:
                            AppColors.primaryDark,
                      ),
                       SizedBox(width: 12),
                       Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ];
        })(),
      ),
      body: Consumer<EventProvider>(
        builder: (
          context,
          provider,
          _,
        ) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    _carteImage(event),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .primarySurface,
                          borderRadius:
                              BorderRadius
                                  .circular(20),
                        ),
                        child: Text(
                          event.categorie.label,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .primaryDark,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.md,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.article_outlined,
                      titre:
                          'À propos de cet événement',
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        AppSpacing.md,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius.card,
                        ),
                        border: Border.all(
                          color: Colors.grey
                              .withValues(
                            alpha: 0.14,
                          ),
                        ),
                      ),
                      child: Text(
                        event.description,
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textPrimary,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.person_outline_rounded,
                      titre: 'Auteur',
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    _carteAuteur(
                      event,
                      dateFormatee,
                    ),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.link_rounded,
                      titre: 'Lien',
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    _carteLien(event),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.event_available_outlined,
                      titre: 'Mon statut',
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        AppSpacing.sm,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors
                                .surfaceMuted,
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius.card,
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            StatutPersonnel
                                .values
                                .map((s) {
                          final selectionne =
                              event.monStatut ==
                                  s;

                          return ChoiceChip(
                            label: Text(
                              '${s.emoji} ${s.label}',
                            ),
                            selected:
                                selectionne,
                            onSelected:
                                (_) async {
                              final succes =
                                  await provider
                                      .changerStatut(
                                event.id,
                                s,
                              );

                              if (!mounted ||
                                  !succes) {
                                return;
                              }

                              setState(() {
                                _event =
                                    event.copyWith(
                                  monStatut: s,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.insights_outlined,
                      titre: 'Statistiques',
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    _carteStatistiques(event),

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    _sectionTitre(
                      icon:
                          Icons.chat_bubble_outline_rounded,
                      titre: 'Commentaires',
                    ),

                    const SizedBox(
                      height: AppSpacing.md,
                    ),

                    if (provider
                        .chargementCommentaires)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          vertical:
                              AppSpacing.lg,
                        ),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else if (provider
                        .commentaires.isEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              AppSpacing.md,
                          vertical:
                              AppSpacing.lg,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .surfaceMuted,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            AppRadius.card,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons
                                  .chat_bubble_outline_rounded,
                              size: 34,
                              color:
                                  Colors.grey,
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Aucun commentaire pour le moment.',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color:
                                    AppColors
                                        .textPrimary,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Soyez le premier à réagir !',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...provider.commentaires
                          .map(
                        (commentaire) =>
                            _carteCommentaire(
                          commentaire,
                        ),
                      ),
                  ],
                ),
              ),

              SafeArea(
                top: false,
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 12,
                        offset:
                            const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            if (_commentaireEnReponse !=
                                null)
                              Container(
                                width: double.infinity,
                                margin:
                                    const EdgeInsets.only(
                                  bottom: 8,
                                ),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: AppColors
                                      .primarySurface,
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '↩️',
                                      style: TextStyle(
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            'Réponse à '
                                            '${_commentaireEnReponse!.nomComplet}',
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  AppColors.primaryDark,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 2,
                                          ),
                                          Text(
                                            _commentaireEnReponse!
                                                .texte,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Annuler',
                                      onPressed: () {
                                        setState(() {
                                          _commentaireEnReponse =
                                              null;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        size: 19,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_afficherSuggestionsMention)
                              _construireSuggestionsMention(),
                            TextField(
                              controller:
                                  _commentaireController,
                          minLines: 1,
                          maxLines: 4,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textPrimary,
                            fontSize: 15,
                          ),
                          cursorColor:
                              AppColors.primary,
                          decoration:
                              InputDecoration(
                            hintText:
                                'Ajouter un commentaire...',
                            hintStyle:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor:
                                AppColors
                                    .surfaceMuted,
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),
                              borderSide:
                                  BorderSide
                                      .none,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),
                              borderSide:
                                  BorderSide(
                                color: Colors
                                    .grey
                                    .withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    AppColors
                                        .primary,
                                width: 1.3,
                              ),
                            ),
                          ),
                          onSubmitted: (_) =>
                              _envoyerCommentaire(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.sm,
                      ),
                      SizedBox(
                        width: 46,
                        height: 46,
                        child:
                            IconButton.filled(
                          onPressed:
                              _envoiCommentaire
                                  ? null
                                  : _envoyerCommentaire,
                          style:
                              IconButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary
                                    .withValues(
                              alpha: 0.45,
                            ),
                          ),
                          icon: _envoiCommentaire
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .send_rounded,
                                  size: 21,
                                ),
                        ),
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
