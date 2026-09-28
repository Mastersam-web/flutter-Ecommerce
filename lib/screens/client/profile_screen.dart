import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/auth_guard.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_helpers.dart';
import 'order_history_screen.dart';

/// Profil de l'utilisateur connecté (client ou vendeur).
/// Un vendeur peut y gérer son numéro WhatsApp.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _whatsappController =
        TextEditingController(text: user?.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      whatsappNumber: auth.isSeller ? _whatsappController.text : null,
    );
    if (!mounted) return;

    showAppSnackBar(
      context,
      ok ? 'Profil mis à jour' : (auth.errorMessage ?? 'Mise à jour impossible'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.isSeller ? 'Profil vendeur' : 'Mon profil'),
      ),
      body: CenteredBox(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 34, color: primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(user.email,
                          style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      Chip(label: Text(user.isSeller ? 'Vendeur' : 'Client')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      appInputDecoration(label: 'Nom', icon: Icons.person),
                  validator: (v) => Validators.required(v, 'Le nom'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      appInputDecoration(label: 'Téléphone', icon: Icons.phone),
                  validator: Validators.phone,
                ),
                if (user.isSeller) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: appInputDecoration(
                      label: 'Numéro WhatsApp',
                      icon: Icons.chat,
                      hint: '+25779123456',
                    ),
                    validator: Validators.whatsapp,
                  ),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Enregistrer',
                  icon: Icons.save,
                  isLoading: auth.isLoading,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      if (user.isClient) ...[
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Mes commandes'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Déconnexion',
                            style: TextStyle(color: Colors.red)),
                        onTap: () => logoutAndReset(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
