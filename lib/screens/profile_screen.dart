import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

/// Enhancement 3: profile UI rendered from the User model, hydrated out of
/// SharedPreferences via UserService.getUser() — no extra API call needed.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    try {
      await _userService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<String?> _requestInput({
    required String title,
    required String label,
    String initialValue = '',
    bool obscureText = false,
    bool trimInput = true,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              trimInput ? controller.text.trim() : controller.text,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _editUsername(User user) async {
    final username = await _requestInput(
      title: 'Update username',
      label: 'Username',
      initialValue: user.username,
    );
    if (username == null || username.length < 3) {
      if (username != null) {
        _showMessage('Username must be at least 3 characters.');
      }
      return;
    }
    try {
      await _userService.updateUsername(username);
      if (!mounted) return;
      final updatedUser = _userService.getUser();
      setState(() {
        _userFuture = updatedUser;
      });
      _showMessage('Username updated.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = await _requestInput(
      title: 'Change password',
      label: 'Current password',
      obscureText: true,
      trimInput: false,
    );
    if (currentPassword == null || currentPassword.isEmpty) return;
    final newPassword = await _requestInput(
      title: 'New password',
      label: '8+ characters, upper/lowercase and a number',
      obscureText: true,
      trimInput: false,
    );
    if (newPassword == null || newPassword.isEmpty) return;
    if (newPassword.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(newPassword) ||
        !RegExp(r'[a-z]').hasMatch(newPassword) ||
        !RegExp(r'[0-9]').hasMatch(newPassword)) {
      _showMessage('Use 8+ characters with upper, lower, and a number.');
      return;
    }
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _showMessage('Password updated.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This permanently deletes your Firebase account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final password = await _requestInput(
      title: 'Confirm your password',
      label: 'Password',
      obscureText: true,
      trimInput: false,
    );
    if (password == null || password.isEmpty) return;
    try {
      await _userService.deleteAccount(password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'Error: ${snapshot.error}',
              fontSize: 14.sp,
            ),
          );
        }

        final user = snapshot.data!;

        if (!user.isValid) {
          return Center(
            child: CustomText(
              text: 'No saved user. Please sign in again.',
              fontSize: 14.sp,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          child: Column(
            children: [
              // Avatar card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44.r,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: Icon(Icons.person, size: 44.sp),
                    ),
                    SizedBox(height: 12.h),
                    CustomText(
                      text: user.fullName.isEmpty
                          ? user.username
                          : user.fullName,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: '@${user.username}',
                      fontSize: 12.sp,
                      color: ThemeProvider.accentGold,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Detail rows straight off the User model
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.email_outlined, 'Email', user.email),
                    const Divider(height: 1),
                    _infoRow(Icons.alternate_email, 'Username', user.username),
                    const Divider(height: 1),
                    _infoRow(Icons.cake_outlined, 'Age', '${user.age}'),
                    const Divider(height: 1),
                    _infoRow(Icons.phone_outlined, 'Contact', user.contactNo),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.badge_outlined,
                      'User ID',
                      user.uid.isEmpty ? '#${user.id}' : user.uid,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editUsername(user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update username'),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change password'),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B5A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: ThemeProvider.primaryNavy),
          SizedBox(width: 12.w),
          CustomText(text: label, fontSize: 13.sp, fontWeight: FontWeight.w600),
          const Spacer(),
          Flexible(
            child: CustomText(
              text: value.isEmpty ? '—' : value,
              fontSize: 12.sp,
              color: Colors.grey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
