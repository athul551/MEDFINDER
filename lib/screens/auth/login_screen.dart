import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../utils/snackbars.dart';
import '../../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AppAuthProvider>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _continueAsGuest() async {
    try {
      await context.read<AppAuthProvider>().signInAsGuest();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Guest login failed.',
          isError: true,
        );
      }
    }
  }

  // Cohesive teal tone, matched to the login background gradient.
  static const _accent = Color(0xFF2DD4BD);
  static const _accentDeep = Color(0xFF0F6E5E);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.20),
                            _accentDeep.withOpacity(0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.40),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /// APP LOGO
                              Center(
                                child: Container(
                                  height: 104,
                                  width: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_accent, _accentDeep],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.55),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accent.withOpacity(0.45),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/medfinder_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.local_hospital_rounded,
                                            size: 54,
                                            color: Colors.white,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              /// WELCOME LABEL
                              Text(
                                "Welcome back",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// TITLE
                              const Text(
                                "MedFinder",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// SUBTITLE
                              Text(
                                "Find medicine & manage your pharmacy",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),

                              const SizedBox(height: 34),

                              /// EMAIL FIELD
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: _accent,
                                decoration: _fieldDecoration(
                                  label: "Email Address",
                                  icon: Icons.email_outlined,
                                ),
                              ),

                              const SizedBox(height: 18),

                              /// PASSWORD FIELD
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: Validators.password,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: _accent,
                                decoration: _fieldDecoration(
                                  label: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// FORGOT PASSWORD
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              /// LOGIN BUTTON
                              _PrimaryButton(
                                isLoading: auth.isLoading,
                                onPressed: auth.isLoading ? null : _login,
                              ),

                              const SizedBox(height: 16),

                              /// GUEST BUTTON
                              SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      auth.isLoading ? null : _continueAsGuest,
                                  icon: const Icon(Icons.person_outline),
                                  label: const Text(
                                    "Continue as Guest",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.10),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.55),
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              /// DIVIDER
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.30),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      "OR",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.30),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              /// CREATE ACCOUNT
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "New to MedFinder?",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: _accent,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RoleSelectionScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1.3]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: border(Colors.white.withOpacity(0.30)),
      enabledBorder: border(Colors.white.withOpacity(0.30)),
      focusedBorder: border(_accent, 2),
      errorStyle: const TextStyle(
        color: Color(0xFFFFD3CF),
        fontWeight: FontWeight.w600,
      ),
      focusedErrorBorder: border(const Color(0xFFFF8A80), 2),
      errorBorder: border(const Color(0xFFFF8A80)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _LoginScreenState._accent,
              _LoginScreenState._accentDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _LoginScreenState._accent.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.login_rounded),
          label: Text(
            isLoading ? "Please wait..." : "Login",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
