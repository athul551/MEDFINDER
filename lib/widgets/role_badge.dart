import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.verified_user_outlined, size: 16),
      label: Text(role.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
