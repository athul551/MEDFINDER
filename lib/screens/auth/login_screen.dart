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

  static const _teal = Color(0xFF2DB5A0);
  static const _tealDark = Color(0xFF1A8F80);

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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(30),

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.14),
                            _teal.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.45),
                          width: 1.5,
                        ),
                      ),

                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.95),
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
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      _teal,
                                      _tealDark,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _teal.withOpacity(0.45),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      'assets/images/medfinder_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.local_hospital_rounded,
                                          size: 58,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            /// TITLE
                            Text(
                              "MedFinder",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// SUBTITLE
                            Text(
                              "Medicine availability & pharmacy management system",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.white.withOpacity(0.88),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 36),

                            /// EMAIL FIELD
                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: Validators.email,
                              style: const TextStyle(color: Colors.white),

                              decoration: InputDecoration(
                                labelText: "Email Address",

                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.9),
                                ),

                                filled: true,
                                fillColor:
                                    Colors.white.withOpacity(0.12),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// PASSWORD FIELD
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.password,
                              style: const TextStyle(color: Colors.white),

                              decoration: InputDecoration(
                                labelText: "Password",

                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                ),

                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                ),

                                filled: true,
                                fillColor:
                                    Colors.white.withOpacity(0.12),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// FORGOT PASSWORD
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// LOGIN BUTTON
                            SizedBox(
                              height: 58,

                              child: ElevatedButton.icon(
                                onPressed:
                                    auth.isLoading ? null : _login,

                                icon: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login),

                                label: Text(
                                  auth.isLoading
                                      ? "Please wait..."
                                      : "Login",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _teal,

                                  foregroundColor: Colors.white,

                                  elevation: 8,

                                  shadowColor:
                                      _teal.withOpacity(0.5),

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            /// GUEST BUTTON
                            SizedBox(
                              height: 56,

                              child: OutlinedButton.icon(
                                onPressed: auth.isLoading
                                    ? null
                                    : _continueAsGuest,

                                icon:
                                    const Icon(Icons.person_outline),

                                label: const Text(
                                  "Continue as Guest",
                                  style: TextStyle(fontSize: 15),
                                ),

                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _teal,

                                  backgroundColor:
                                      _teal.withOpacity(0.12),

                                  side: const BorderSide(
                                    color: _teal,
                                    width: 1.5,
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
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
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// CREATE ACCOUNT
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [

                                Text(
                                  "New to MedFinder?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.88),
                                  ),
                                ),

                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RoleSelectionScreen(),
                                      ),
                                    );
                                  },

                                  child: Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
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
}
