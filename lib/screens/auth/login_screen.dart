
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7F7FA),
              Color(0xFFD8F0F5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),

        child: SafeArea(
          child: Stack(
            children: [

              /// TOP RIGHT CIRCLE
              Positioned(
                top: -60,
                right: -50,
                child: Container(
                  height: 220,
                  width: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withOpacity(0.08),
                  ),
                ),
              ),

              /// BOTTOM LEFT CIRCLE
              Positioned(
                bottom: -70,
                left: -60,
                child: Container(
                  height: 260,
                  width: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.05),
                  ),
                ),
              ),

              /// CONTENT
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),

                    child: Container(
                      padding: const EdgeInsets.all(30),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.12),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 12),
                          ),
                        ],
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
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.teal.shade700,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.35),
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
                                color: Colors.teal.shade900,
                                letterSpacing: 1,
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
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 36),

                            /// EMAIL FIELD
                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: Validators.email,

                              decoration: InputDecoration(
                                labelText: "Email Address",

                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.teal.shade700,
                                ),

                                filled: true,
                                fillColor:
                                    Colors.teal.withOpacity(0.04),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.teal.shade400,
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

                              decoration: InputDecoration(
                                labelText: "Password",

                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.teal.shade700,
                                ),

                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
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
                                    Colors.teal.withOpacity(0.04),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.teal.shade400,
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
                                    color: Colors.teal.shade700,
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
                                  backgroundColor:
                                      Colors.teal.shade700,

                                  foregroundColor: Colors.white,

                                  elevation: 8,

                                  shadowColor:
                                      Colors.teal.withOpacity(0.4),

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
                                  foregroundColor:
                                      Colors.teal.shade700,

                                  side: BorderSide(
                                    color: Colors.teal.shade200,
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
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
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
                                    color: Colors.grey.shade700,
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
                                      color:
                                          Colors.teal.shade700,
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
            ],
          ),
        ),
      ),
    );
  }
}