import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/download_helper.dart';
import 'package:provider/provider.dart';

import '../providers/app_auth_provider.dart';
import '../services/storage_service.dart';
import '../utils/snackbars.dart';
import '../widgets/role_badge.dart';

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
    if (user == null) {
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      final bytes = await pickedFile.readAsBytes();
      // save a local copy in app documents directory
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
        if (mounted) {
          showAppSnackBar(context, 'Saved image locally: $localPath');
        }
      } else {
        try {
          final filename = 'profile_${user.uid}_$timestamp.jpg';
          await downloadBytes(bytes, filename, 'image/jpeg');
          if (mounted) showAppSnackBar(context, 'Downloaded image: $filename');
        } catch (e) {
          if (mounted) showAppSnackBar(context, 'Could not download image: $e', isError: true);
        }
      }
      final imageUrl = await StorageService().uploadProfileImage(
        userId: user.uid,
        bytes: bytes,
        onProgress: (p) {
          if (mounted) {
            setState(() => _uploadProgress = p);
          }
        },
      );
      await auth.updateProfileImage(imageUrl);
      if (mounted) {
        showAppSnackBar(context, 'Profile image updated.');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not upload profile image: $error',
          isError: true,
        );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No profile available.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!) as ImageProvider
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name.characters.first.toUpperCase()
                                    : 'U',
                                style: Theme.of(context).textTheme.headlineMedium,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _isUploading ? null : _pickProfileImage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _isUploading
                                ? SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: _uploadProgress,
                                          strokeWidth: 2.5,
                                          color: Colors.teal,
                                        ),
                                        if (_uploadProgress != null)
                                          Text(
                                            '${(_uploadProgress! * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: RoleBadge(role: user.role)),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone'),
                        subtitle: Text(user.phone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  onPressed: () => context.read<AppAuthProvider>().signOut(),
                ),
              ],
            ),
    );
  }
}
