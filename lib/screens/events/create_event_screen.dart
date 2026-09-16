import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/storage_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lienController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  CategorieEvent _categorie = CategorieEvent.autre;
  File? _image;
  String? _imageUrl;
  bool _enCours = false;
  bool _isUploading = false;

  static const int _maxDescriptionLength = 1000;

  @override
  void dispose() {
    _lienController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      setState(() {
        _image = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sélectionner cette image.'),
        ),
      );
    }
  }

  Future<String?> _uploaderImage() async {
    if (_image == null) return null;

    setState(() => _isUploading = true);

    try {
      final storageService = context.read<StorageService>();

      final response = await storageService.uploadFile(
        '/events/upload',
        file: _image!,
        fieldName: 'file',
      ) as Map<String, dynamic>;

      if (!mounted) return null;

      if (response['success'] == true && response['image_url'] != null) {
        setState(() => _isUploading = false);
        return response['image_url'] as String;
      } else {
        setState(() => _isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'upload de l\'image: '
              '${response['detail'] ?? response['message'] ?? 'Erreur inconnue'}',
            ),
          ),
        );

        return null;
      }
    } catch (e) {
      if (!mounted) return null;

      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload de l\'image: $e'),
        ),
      );

      return null;
    }
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;

    final groupId = context.read<GroupProvider>().groupeCourant?.id;

    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun groupe sélectionné')),
      );
      return;
    }

    setState(() => _enCours = true);

    if (_image != null) {
      final uploadedUrl = await _uploaderImage();

      if (!mounted) return;

      if (uploadedUrl == null) {
        setState(() => _enCours = false);
        return;
      }

      _imageUrl = uploadedUrl;
    }

    final events = context.read<EventProvider>();

    final succes = await events.creerEvent(
      groupId: groupId,
      lien: _lienController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrl,
      categorie: _categorie,
    );

    if (!mounted) return;

    setState(() => _enCours = false);

    if (succes) {
      Navigator.of(context).pop();
    } else if (events.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(events.errorMessage!)),
      );
    }
  }

  String? _validerLien(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le lien est obligatoire';
    }

    final uri = Uri.tryParse(value.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      return 'Lien invalide (doit commencer par http/https)';
    }

    return null;
  }

  String? _validerDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La description est obligatoire';
    }

    if (value.length > _maxDescriptionLength) {
      return 'La description ne peut pas dépasser 1000 caractères';
    }

    final wordCount = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    if (wordCount < 10) {
      return 'La description doit contenir au moins 10 mots';
    }

    return null;
  }

  void _afficherApercuImage() {
    if (_image == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.file(
                      _image!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Retour',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.all(9),
                      minimumSize: const Size(42, 42),
                      maximumSize: const Size(42, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Créer un événement',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                floating: true,
                snap: true,
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                foregroundColor: AppColors.textPrimary,
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                surfaceTintColor: Colors.transparent,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Text(
                          'Type d\'événement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: CategorieEvent.values.map((c) {
                            final selectionne = _categorie == c;

                            return ChoiceChip(
                              label: Text('${c.emoji} ${c.label}'),
                              selected: selectionne,
                              onSelected: (_) {
                                setState(() => _categorie = c);
                              },
                              labelStyle: TextStyle(
                                color: selectionne
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              selectedColor: AppColors.primary,
                              side: BorderSide(
                                color: selectionne
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Renseigner le lien de l\'événement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _lienController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          cursorColor: AppColors.primary,
                          decoration:  InputDecoration(
                            labelText: 'Lien de l\'événement',
                            hintText: 'https://example.com/evenement',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ), 
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            )
                          ),
                          validator: _validerLien,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Description de l\'événement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          maxLength: _maxDescriptionLength,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          cursorColor: AppColors.primary,
                          decoration:  InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Décrivez l\'événement en détail (minimum 10 mots)',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: _validerDescription,
                          onChanged: (_) {
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                            setState(() {});
                          },
                        ),
                        if (_descriptionController.text.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _validerDescription(
                                              _descriptionController.text,
                                            ) ==
                                            null
                                        ? 'Description valide'
                                        : 'Minimum 10 mots requis',
                                    style: TextStyle(
                                      color: _validerDescription(
                                                _descriptionController.text,
                                              ) ==
                                              null
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${_descriptionController.text.length}/$_maxDescriptionLength caractères',
                                  style: TextStyle(
                                    color: _descriptionController.text.length >=
                                            _maxDescriptionLength
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Ajouter l\'image de l\'événement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: _enCours ? null : _choisirImage,
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Appuyez pour choisir une image',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image facultative mais recommandée',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _image!,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder:
                                                const CircleBorder(),
                                            onTap: () {
                                              setState(() {
                                                _image = null;
                                                _imageUrl = null;
                                              });
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        child: Material(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: InkWell(
                                            onTap: _afficherApercuImage,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.visibility_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Aperçu',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Material(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: InkWell(
                                            onTap: _choisirImage,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Changer',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isUploading)
                                        const Positioned(
                                          top: 10,
                                          left: 10,
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _enCours ? null : _publier,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                            ),
                            child: _enCours
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Publier l\'événement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}