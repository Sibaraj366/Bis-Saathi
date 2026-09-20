import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onCreateAccount;

  final ValueChanged<Map<String, dynamic>?>? onLoginSuccess;

  const LoginScreen({super.key, this.onCreateAccount, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        // IMPORTANT:
        // The backend already returns the authenticated user,
        // including the user's role.
        //
        // We pass that user directly to AuthGate instead of
        // making another /me request.
        widget.onLoginSuccess?.call(result.user);
      } else {
        _showError(
          result.message.isNotEmpty
              ? result.message
              : 'Login failed. Please try again.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // EMAIL VALIDATION
  // ==========================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // ==========================================================
  // PASSWORD VALIDATION
  // ==========================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // ==================================================
                  // LOGO / BRAND
                  // ==================================================
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,

                      decoration: BoxDecoration(
                        color: const Color(0xFF0B5ED7),
                        borderRadius: BorderRadius.circular(20),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: const Icon(
                        Icons.verified_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,

                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue with BIS Saathi',
                    textAlign: TextAlign.center,

                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Form(
                      key: _formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          // ==================================================
                          // EMAIL
                          // ==================================================
                          TextFormField(
                            controller: _emailController,

                            keyboardType: TextInputType.emailAddress,

                            textInputAction: TextInputAction.next,

                            enabled: !_isLoading,

                            validator: _validateEmail,

                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',

                              prefixIcon: const Icon(Icons.email_outlined),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: const BorderSide(
                                  color: Color(0xFF0B5ED7),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==================================================
                          // PASSWORD
                          // ==================================================
                          TextFormField(
                            controller: _passwordController,

                            obscureText: _obscurePassword,

                            textInputAction: TextInputAction.done,

                            enabled: !_isLoading,

                            validator: _validatePassword,

                            onFieldSubmitted: (_) {
                              _login();
                            },

                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',

                              prefixIcon: const Icon(Icons.lock_outline),

                              suffixIcon: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },

                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: const BorderSide(
                                  color: Color(0xFF0B5ED7),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // LOGIN BUTTON
                          // ==================================================
                          SizedBox(
                            height: 54,

                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B5ED7),

                                foregroundColor: Colors.white,

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,

                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',

                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==================================================
                          // CREATE ACCOUNT
                          // ==================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                "Don't have an account?",

                                style: TextStyle(color: Colors.grey.shade600),
                              ),

                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : widget.onCreateAccount,

                                child: const Text(
                                  'Create Account',

                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // FOOTER
                  // ==================================================
                  Text(
                    'BIS Saathi • AI-powered BIS Standards Assistant',

                    textAlign: TextAlign.center,

                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
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
