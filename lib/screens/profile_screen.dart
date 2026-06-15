import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/pharmacy.dart';
import '../providers/app_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';
import '../utils/snackbars.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  double? _uploadProgress;

  Future<void> _pickProfileImage() async {
    final auth = context.read<AppAuthProvider>();
    final user = auth.appUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final localDir = Directory('${appDir.path}/profile_images');
        if (!await localDir.exists()) {
          await localDir.create(recursive: true);
        }
        final localPath = '${localDir.path}/profile_${user.uid}_$timestamp.jpg';
        final localFile = File(localPath);
        await localFile.writeAsBytes(bytes);
        if (mounted) showAppSnackBar(context, 'Saved image locally: $localPath');
      } else {
        if (mounted) showAppSnackBar(context, 'Local file save not supported on web.');
      }

      const maxFirestoreBytes = 150 * 1024;
      if (bytes.lengthInBytes <= maxFirestoreBytes) {
        try {
          final b64 = base64Encode(bytes);
          final dataUri = 'data:image/jpeg;base64,$b64';
          await auth.updateProfileImage(dataUri);
          if (mounted) showAppSnackBar(context, 'Profile image saved.');
          return;
        } catch (e) {
          if (mounted) showAppSnackBar(context, 'Could not save to Firestore: $e', isError: true);
        }
      }

      final imageUrl = await StorageService().uploadProfileImage(
        userId: user.uid,
        bytes: bytes,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      await auth.updateProfileImage(imageUrl);
      if (mounted) showAppSnackBar(context, 'Profile image updated.');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Could not upload profile image: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.appUser;
    final isPharmacy = user?.role == UserRole.pharmacyOwner;

    return Scaffold(
      body: user == null
          ? const Center(child: Text('No profile available.'))
          : CustomScrollView(
              slivers: [
                _ProfileHeader(
                  user: user,
                  isUploading: _isUploading,
                  uploadProgress: _uploadProgress,
                  onImageTap: _pickProfileImage,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UserInfoSection(user: user),
                        const SizedBox(height: 20),
                        if (isPharmacy) ...[
                          _PharmacyInfoSection(),
                          const SizedBox(height: 20),
                        ],
                        _QuickActionsSection(user: user),
                        const SizedBox(height: 20),
                        _AccountSection(user: user),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser user;
  final bool isUploading;
  final double? uploadProgress;
  final VoidCallback onImageTap;

  const _ProfileHeader({
    required this.user,
    required this.isUploading,
    required this.uploadProgress,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF004D40),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF004D40),
                Color(0xFF00796B),
                Color(0xFF009688),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: isUploading ? null : onImageTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).round()),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
                          backgroundImage: user.profileImageUrl != null
                              ? (user.profileImageUrl!.startsWith('data:')
                                  ? MemoryImage(base64Decode(user.profileImageUrl!.split(',').last)) as ImageProvider
                                  : NetworkImage(user.profileImageUrl!) as ImageProvider)
                              : null,
                          child: user.profileImageUrl == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name.characters.first.toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (isUploading)
                        Positioned(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.5 * 255).round()),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: uploadProgress,
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                  if (uploadProgress != null)
                                    Text(
                                      '${(uploadProgress! * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!isUploading)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((0.2 * 255).round()),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.role == UserRole.customer
                            ? Icons.person_outline
                            : Icons.storefront_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.role == UserRole.customer ? 'Customer' : 'Pharmacy Owner',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

class _UserInfoSection extends StatelessWidget {
  final AppUser user;

  const _UserInfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF00796B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const Divider(height: 32),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF004D40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PharmacyInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pharmacy?>(
      stream: context.read<FirestoreService>().watchPharmacyForOwner(
            context.read<AppAuthProvider>().appUser!.uid,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final pharmacy = snapshot.data;
        if (pharmacy == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.04 * 255).round()),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF00796B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Pharmacy Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF004D40),
                      ),
                    ),
                  ),
                  if (pharmacy.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Color(0xFF00C853)),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00C853),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoTile(
                icon: Icons.store_outlined,
                label: 'Pharmacy Name',
                value: pharmacy.name,
              ),
              const Divider(height: 32),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: pharmacy.address,
              ),
              const SizedBox(height: 16),
              _RatingRow(
                rating: pharmacy.averageRating,
                reviewCount: pharmacy.reviewCount,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, size: 20, color: Color(0xFFFFB300)),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF004D40),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($reviewCount reviews)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (index) {
                  if (index < rating.floor()) {
                    return const Icon(Icons.star, size: 14, color: Colors.amber);
                  } else if (index < rating && rating - index >= 0.5) {
                    return const Icon(Icons.star_half, size: 14, color: Colors.amber);
                  }
                  return Icon(Icons.star_border, size: 14, color: Colors.grey.shade300);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final AppUser user;

  const _QuickActionsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bolt_outlined,
                  color: Color(0xFF00796B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DarkModeToggle(
            isDark: isDark,
            onToggle: () => themeProvider.toggleTheme(),
          ),
          const Divider(height: 8),
          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              showAppSnackBar(context, 'Password reset email sent.');
            },
          ),
          const Divider(height: 8),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              showAppSnackBar(context, 'Notification settings coming soon.');
            },
          ),
          const Divider(height: 8),
          _ActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
            onTap: () {
              showAppSnackBar(context, 'Support coming soon.');
            },
          ),
        ],
      ),
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _DarkModeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Dark theme enabled' : 'Light theme enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => onToggle(),
              activeThumbColor: const Color(0xFF00796B),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final AppUser user;

  const _AccountSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF00796B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.read<AppAuthProvider>().signOut(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withAlpha((0.3 * 255).round())),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AppAuthProvider>().deleteAccount();
              } catch (error) {
                if (context.mounted) {
                  final message = error.toString().contains('requires-recent-login')
                      ? 'Your session expired. Please sign out, sign back in, and try again.'
                      : 'Failed to delete account: $error';
                  showAppSnackBar(context, message, isError: true);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
