import 'package:flutter/material.dart';

import '../../utils/app_constants.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose account type')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _RoleTile(
            icon: Icons.person_outline,
            title: 'Customer / Patient',
            subtitle: 'Search nearby stock and reserve medicine.',
            onTap: () => _openRegister(context, UserRole.customer),
          ),
          const SizedBox(height: 12),
          _RoleTile(
            icon: Icons.storefront_outlined,
            title: 'Pharmacy Owner',
            subtitle: 'Manage medicine stock and reservations.',
            onTap: () => _openRegister(context, UserRole.pharmacyOwner),
          ),
        ],
      ),
    );
  }

  void _openRegister(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
