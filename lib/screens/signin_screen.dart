import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isCreatingAccount = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isCreatingAccount) {
        await _userService.createAccount(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          age: int.parse(_ageController.text),
          contactNo: _contactController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        await _userService.signOut();
        if (!mounted) return;
        setState(() {
          _isCreatingAccount = false;
          _passwordController.clear();
        });
        _showError('Account created. Please sign in.');
      } else {
        await _userService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Authentication failed.');
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        validator: validator ?? (value) => _required(value, label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/nuicon.jpeg',
                        width: 36.w,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.school, size: 28.sp),
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: _isCreatingAccount ? 'Create account' : 'Welcome',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Sign in')),
                      ButtonSegment(value: true, label: Text('Create account')),
                    ],
                    selected: {_isCreatingAccount},
                    onSelectionChanged: _isLoading
                        ? null
                        : (selection) => setState(
                            () => _isCreatingAccount = selection.first,
                          ),
                  ),
                  SizedBox(height: 22.h),
                  if (_isCreatingAccount) ...[
                    _field(
                      controller: _firstNameController,
                      label: 'First name',
                      icon: Icons.person_outline,
                    ),
                    _field(
                      controller: _lastNameController,
                      label: 'Last name',
                      icon: Icons.person_outline,
                    ),
                    _field(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null || age < 13 || age > 120) {
                          return 'Enter an age from 13 to 120';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: _contactController,
                      label: 'Contact number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final contact = value?.trim() ?? '';
                        if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(contact)) {
                          return 'Enter a valid contact number';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      validator: (value) {
                        final error = _required(value, 'Username');
                        if (error != null) return error;
                        if (value!.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                  _field(
                    controller: _emailController,
                    label: 'Email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  _field(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (!_isCreatingAccount) {
                        return _required(value, 'Password');
                      }
                      if (value == null ||
                          value.length < 8 ||
                          !RegExp(r'[A-Z]').hasMatch(value) ||
                          !RegExp(r'[a-z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Use 8+ characters with upper, lower, and a number';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeProvider.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : CustomText(
                              text: _isCreatingAccount
                                  ? 'Create account'
                                  : 'Sign in',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
