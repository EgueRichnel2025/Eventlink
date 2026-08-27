import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final succes = await auth.creerProfil(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.groupeChoice);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Faisons connaissance', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ces informations identifieront vos événements et vos commentaires auprès des autres membres.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prénom', hintText: 'Ex : Richnel'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le prénom est obligatoire' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nom', hintText: 'Ex : EGUE'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                ),
                const Spacer(),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _continuer,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Continuer'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
