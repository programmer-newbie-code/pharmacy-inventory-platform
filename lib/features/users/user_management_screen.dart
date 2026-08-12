import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../data/media_storage_service.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

final usersListFutureProvider = FutureProvider.autoDispose<List<User>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.listUsers();
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  Future<void> _showAddUserDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'kasir';
    String? photoPath;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addUserButton),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      final path = await MediaStorageService().saveImage(
                        picked.path,
                        folder: 'users',
                      );
                      setDialogState(() => photoPath = path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withAlpha(20),
                    backgroundImage:
                        photoPath != null && File(photoPath!).existsSync()
                            ? FileImage(File(photoPath!))
                            : null,
                    child: photoPath == null || !File(photoPath!).existsSync()
                        ? const Icon(Icons.add_a_photo,
                            size: 28, color: AppTheme.primaryColor)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('addUsernameInput'),
                  controller: usernameController,
                  decoration: InputDecoration(labelText: l10n.usernameLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('addPasswordInput'),
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.passwordLabel),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(labelText: l10n.roleLabel),
                  items: [
                    const DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                    const DropdownMenuItem(
                        value: 'inventory', child: Text('Inventory')),
                    DropdownMenuItem(
                        value: 'kasir', child: Text(l10n.roleCashier)),
                    const DropdownMenuItem(
                        value: 'audit', child: Text('Auditor')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              key: const Key('submitAddUserBtn'),
              onPressed: () async {
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();
                if (username.isNotEmpty && password.isNotEmpty) {
                  final hasher = ref.read(passwordHasherProvider);
                  final hash = hasher.hash(password);
                  await ref.read(userRepositoryProvider).createUser(
                        username: username,
                        passwordHash: hash,
                        role: selectedRole,
                        photoPath: photoPath,
                      );
                  ref.invalidate(usersListFutureProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetPasswordDialog(User user) async {
    final l10n = AppLocalizations.of(context)!;
    final passController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.resetPasswordButton} (${user.username})'),
        content: TextField(
          key: const Key('resetPasswordInput'),
          controller: passController,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.newPasswordLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('submitResetPassBtn'),
            onPressed: () async {
              final newPass = passController.text.trim();
              if (newPass.isNotEmpty) {
                final hasher = ref.read(passwordHasherProvider);
                final newHash = hasher.hash(newPass);
                await ref.read(userRepositoryProvider).updateUserPassword(
                      userId: user.id,
                      newPasswordHash: newHash,
                    );
                ref.invalidate(usersListFutureProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeRoleDialog(User user) async {
    final l10n = AppLocalizations.of(context)!;
    String newRole = user.role;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${l10n.changeRoleButton} (${user.username})'),
          content: DropdownButtonFormField<String>(
            initialValue: newRole,
            decoration: InputDecoration(labelText: l10n.roleLabel),
            items: [
              const DropdownMenuItem(value: 'admin', child: Text('Admin')),
              const DropdownMenuItem(
                  value: 'inventory', child: Text('Inventory')),
              DropdownMenuItem(value: 'kasir', child: Text(l10n.roleCashier)),
              const DropdownMenuItem(value: 'audit', child: Text('Auditor')),
            ],
            onChanged: (val) {
              if (val != null) {
                setDialogState(() => newRole = val);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              key: const Key('submitChangeRoleBtn'),
              onPressed: () async {
                await ref.read(userRepositoryProvider).updateUserRole(
                      userId: user.id,
                      newRole: newRole,
                    );
                ref.invalidate(usersListFutureProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeUserPhoto(User user) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await MediaStorageService().saveImage(
      picked.path,
      folder: 'users',
    );
    await ref.read(userRepositoryProvider).updateUserPhoto(
          userId: user.id,
          photoPath: path,
        );
    ref.invalidate(usersListFutureProvider);
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'inventory':
        return Colors.blue;
      case 'kasir':
        return Colors.green;
      case 'audit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authSessionProvider);
    final permChecker = ref.watch(permissionCheckerProvider);
    final isAllowed =
        currentUser == null || permChecker.canManageUsers(currentUser.role);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.userManagementTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 64, color: AppTheme.dangerColor.withAlpha(150)),
              const SizedBox(height: 16),
              Text(
                'Akses Ditolak',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Manajemen karyawan hanya dapat diakses oleh Admin.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final usersAsync = ref.watch(usersListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userManagementTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addUserFab'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addUserButton),
        onPressed: _showAddUserDialog,
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
                child: Text('No employee accounts registered.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getRoleColor(user.role).withValues(alpha: 0.2),
                    backgroundImage: user.photoPath != null &&
                            File(user.photoPath!).existsSync()
                        ? FileImage(File(user.photoPath!))
                        : null,
                    child: user.photoPath == null ||
                            !File(user.photoPath!).existsSync()
                        ? Icon(Icons.person, color: _getRoleColor(user.role))
                        : null,
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Role: ${user.role.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('changePhotoBtn_${user.id}'),
                        tooltip: l10n.changePhotoTooltip,
                        icon: const Icon(Icons.photo_camera_outlined),
                        onPressed: () => _changeUserPhoto(user),
                      ),
                      IconButton(
                        key: Key('changeRoleBtn_${user.id}'),
                        tooltip: l10n.changeRoleButton,
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        onPressed: () => _showChangeRoleDialog(user),
                      ),
                      IconButton(
                        key: Key('resetPasswordBtn_${user.id}'),
                        tooltip: l10n.resetPasswordButton,
                        icon: const Icon(Icons.lock_reset),
                        onPressed: () => _showResetPasswordDialog(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
