import 'package:flutter/material.dart' as material;

import 'screens/home_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/standards_screen.dart';
import 'screens/compliance_screen.dart';
import 'screens/document_qa_screen.dart';
import 'screens/services_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_screen.dart';

import 'widgets/responsive_shell.dart';
import 'services/app_language.dart';
import 'services/api_service.dart';

void main() {
  material.runApp(const BISSaathiApp());
}

// ============================================================
// BIS SAATHI APP
// ============================================================

class BISSaathiApp extends material.StatelessWidget {
  const BISSaathiApp({super.key});

  static const material.Color bisBlue = material.Color(0xFF0B5ED7);

  static const material.Color background = material.Color(0xFFF7F9FC);

  @override
  material.Widget build(material.BuildContext context) {
    return material.MaterialApp(
      title: 'BIS Saathi',

      debugShowCheckedModeBanner: false,

      // ========================================================
      // THEME
      // ========================================================
      theme: material.ThemeData(
        useMaterial3: true,

        colorScheme: material.ColorScheme.fromSeed(
          seedColor: bisBlue,
          brightness: material.Brightness.light,
        ),

        scaffoldBackgroundColor: background,

        appBarTheme: const material.AppBarTheme(
          backgroundColor: material.Colors.white,

          surfaceTintColor: material.Colors.white,

          elevation: 0,
        ),

        inputDecorationTheme: const material.InputDecorationTheme(
          filled: true,

          fillColor: material.Colors.white,

          border: material.OutlineInputBorder(
            borderRadius: material.BorderRadius.all(
              material.Radius.circular(12),
            ),

            borderSide: material.BorderSide(color: material.Color(0xFFE2E7F0)),
          ),

          enabledBorder: material.OutlineInputBorder(
            borderRadius: material.BorderRadius.all(
              material.Radius.circular(12),
            ),

            borderSide: material.BorderSide(color: material.Color(0xFFE2E7F0)),
          ),

          focusedBorder: material.OutlineInputBorder(
            borderRadius: material.BorderRadius.all(
              material.Radius.circular(12),
            ),

            borderSide: material.BorderSide(color: bisBlue, width: 1.5),
          ),
        ),
      ),

      // ========================================================
      // AUTHENTICATION ENTRY POINT
      // ========================================================
      home: const AuthGate(),

      // ========================================================
      // SECONDARY ROUTES
      // ========================================================
      routes: {
        '/assistant': (context) {
          return LanguageScope(child: const AssistantScreen());
        },

        '/standards': (context) {
          return LanguageScope(child: const StandardsScreen());
        },

        '/compliance': (context) {
          return LanguageScope(child: const ComplianceScreen());
        },

        '/document-qa': (context) {
          return LanguageScope(child: const DocumentQAScreen());
        },

        '/services': (context) {
          return LanguageScope(child: const ServicesScreen());
        },

        '/profile': (context) {
          return LanguageScope(child: const ProfileScreen());
        },
      },
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends material.StatefulWidget {
  const AuthGate({super.key});

  @override
  material.State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends material.State<AuthGate> {
  bool _isChecking = true;

  bool _isLoggedIn = false;

  bool _loginPromptShown = false;

  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();

    _checkAuthentication();
  }

  // ==========================================================
  // CHECK AUTHENTICATION
  // ==========================================================

  Future<void> _checkAuthentication() async {
    try {
      final loggedIn = await ApiService.isLoggedIn();

      if (!loggedIn) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoggedIn = false;
          _currentUser = null;
          _isChecking = false;
        });

        _showLoginPromptAfterBuild();

        return;
      }

      final user = await ApiService.getCurrentUser();

      if (!mounted) {
        return;
      }

      final normalizedUser = _normalizeUser(user);

      setState(() {
        _isLoggedIn = true;
        _currentUser = normalizedUser;
        _isChecking = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      await ApiService.logout();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggedIn = false;
        _currentUser = null;
        _isChecking = false;
      });

      _showLoginPromptAfterBuild();
    }
  }

  // ==========================================================
  // NORMALIZE USER
  // ==========================================================

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> response) {
    // --------------------------------------------------------
    // Direct user object
    // --------------------------------------------------------

    if (response.containsKey('role')) {
      return Map<String, dynamic>.from(response);
    }

    // --------------------------------------------------------
    // { user: {...} }
    // --------------------------------------------------------

    final dynamic userValue = response['user'];

    if (userValue is Map) {
      final user = Map<String, dynamic>.from(userValue);

      if (user.containsKey('role')) {
        return user;
      }

      final dynamic nestedData = user['data'];

      if (nestedData is Map) {
        final nestedUser = Map<String, dynamic>.from(nestedData);

        if (nestedUser.containsKey('role')) {
          return nestedUser;
        }
      }
    }

    // --------------------------------------------------------
    // { data: { user: {...} } }
    // --------------------------------------------------------

    final dynamic dataValue = response['data'];

    if (dataValue is Map) {
      final data = Map<String, dynamic>.from(dataValue);

      final dynamic nestedUser = data['user'];

      if (nestedUser is Map) {
        final user = Map<String, dynamic>.from(nestedUser);

        if (user.containsKey('role')) {
          return user;
        }
      }

      if (data.containsKey('role')) {
        return data;
      }
    }

    return Map<String, dynamic>.from(response);
  }

  // ==========================================================
  // SHOW LOGIN POPUP AFTER HOME BUILDS
  // ==========================================================

  void _showLoginPromptAfterBuild() {
    if (_loginPromptShown) {
      return;
    }

    material.WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loginPromptShown || _isLoggedIn) {
        return;
      }

      _showLoginPrompt();
    });
  }

  // ==========================================================
  // LOGIN POPUP
  // ==========================================================

  Future<void> _showLoginPrompt() async {
    if (!mounted || _loginPromptShown || _isLoggedIn) {
      return;
    }

    _loginPromptShown = true;

    await material.showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        return _WelcomeLoginDialog(
          onLogin: () {
            material.Navigator.of(dialogContext).pop();

            material.WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _openLogin();
              }
            });
          },

          onSignUp: () {
            material.Navigator.of(dialogContext).pop();

            material.WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showSignup();
              }
            });
          },

          onContinueAsGuest: _continueAsGuest,
        );
      },
    );

    if (mounted) {
      _loginPromptShown = false;
    }
  }

  // ==========================================================
  // OPEN LOGIN
  // ==========================================================

  void _openLogin() {
    if (!mounted) {
      return;
    }

    material.Navigator.of(context).push(
      material.MaterialPageRoute(
        builder: (context) {
          return LoginScreen(
            onCreateAccount: _showSignup,

            onLoginSuccess: _handleLoginSuccess,
          );
        },
      ),
    );
  }

  // ==========================================================
  // CONTINUE AS GUEST
  // ==========================================================

  void _continueAsGuest() {
    if (!mounted) {
      return;
    }

    material.Navigator.of(context, rootNavigator: true).pop();
  }

  // ==========================================================
  // OPEN SIGNUP
  // ==========================================================

  void _showSignup() {
    if (!mounted) {
      return;
    }

    material.Navigator.of(context).push(
      material.MaterialPageRoute(
        builder: (context) {
          return SignupScreen(
            onLogin: () {
              material.Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // LOGIN SUCCESS
  // ==========================================================

  Future<void> _handleLoginSuccess(Map<String, dynamic>? userFromLogin) async {
    if (!mounted) {
      return;
    }

    // The login API already returned the authenticated
    // user's data and role. Use it directly.
    Map<String, dynamic>? normalizedUser;

    if (userFromLogin != null) {
      normalizedUser = _normalizeUser(userFromLogin);
    }

    // --------------------------------------------------------
    // FALLBACK
    //
    // If for any reason the login response did not include
    // the user object, use /me as a fallback.
    // --------------------------------------------------------

    if (normalizedUser == null || !normalizedUser.containsKey('role')) {
      try {
        final user = await ApiService.getCurrentUser();

        normalizedUser = _normalizeUser(user);
      } catch (error) {
        if (!mounted) {
          return;
        }

        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text(
              'Login succeeded, but the user profile could not be loaded.',
            ),
            backgroundColor: material.Colors.red.shade700,
          ),
        );

        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = normalizedUser;

      _isLoggedIn = true;

      _isChecking = false;
    });

    // --------------------------------------------------------
    // REMOVE LOGIN SCREEN
    // --------------------------------------------------------

    final navigator = material.Navigator.of(context, rootNavigator: true);

    navigator.popUntil((route) => route.isFirst);
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _handleLogout() async {
    if (!mounted) {
      return;
    }

    await ApiService.logout();

    if (!mounted) {
      return;
    }

    final navigator = material.Navigator.of(context, rootNavigator: true);

    navigator.popUntil((route) => route.isFirst);

    setState(() {
      _isLoggedIn = false;
      _currentUser = null;
      _isChecking = false;
      _loginPromptShown = false;
    });

    _showLoginPromptAfterBuild();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  material.Widget build(material.BuildContext context) {
    // --------------------------------------------------------
    // CHECKING AUTHENTICATION
    // --------------------------------------------------------

    if (_isChecking) {
      return const _AuthLoadingScreen();
    }

    // --------------------------------------------------------
    // LOGGED IN
    // --------------------------------------------------------

    if (_isLoggedIn) {
      return MainApplicationShell(user: _currentUser, onLogout: _handleLogout);
    }

    // --------------------------------------------------------
    // GUEST HOME
    // --------------------------------------------------------

    return _PublicHomeView(onLogin: _openLogin);
  }
}

// ============================================================
// PUBLIC HOME VIEW
// ============================================================

class _PublicHomeView extends material.StatelessWidget {
  final material.VoidCallback onLogin;

  const _PublicHomeView({required this.onLogin});

  @override
  material.Widget build(material.BuildContext context) {
    return material.Stack(
      children: [
        // ======================================================
        // PUBLIC HOME
        // ======================================================
        const LanguageScope(child: HomeScreen()),

        // ======================================================
        // TOP RIGHT LOGIN BUTTON
        // ======================================================
        material.SafeArea(
          child: material.Align(
            alignment: material.Alignment.topRight,

            child: material.Padding(
              padding: const material.EdgeInsets.only(top: 12, right: 14),

              child: material.Material(
                color: material.Colors.white,

                elevation: 3,

                borderRadius: material.BorderRadius.circular(12),

                child: material.InkWell(
                  onTap: onLogin,

                  borderRadius: material.BorderRadius.circular(12),

                  child: material.Container(
                    height: 42,

                    padding: const material.EdgeInsets.symmetric(
                      horizontal: 14,
                    ),

                    decoration: material.BoxDecoration(
                      borderRadius: material.BorderRadius.circular(12),

                      border: material.Border.all(
                        color: material.Color(0xFFD9E3F2),
                      ),
                    ),

                    child: const material.Row(
                      mainAxisSize: material.MainAxisSize.min,

                      children: [
                        material.Icon(
                          material.Icons.login_rounded,

                          size: 18,

                          color: material.Color(0xFF0B5ED7),
                        ),

                        material.SizedBox(width: 7),

                        material.Text(
                          'Login',

                          style: material.TextStyle(
                            color: material.Color(0xFF084298),

                            fontSize: 13.5,

                            fontWeight: material.FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WELCOME LOGIN DIALOG
// ============================================================

class _WelcomeLoginDialog extends material.StatelessWidget {
  final material.VoidCallback onLogin;

  final material.VoidCallback onSignUp;

  final material.VoidCallback onContinueAsGuest;

  const _WelcomeLoginDialog({
    required this.onLogin,
    required this.onSignUp,
    required this.onContinueAsGuest,
  });

  static const material.Color bisBlue = material.Color(0xFF0B5ED7);

  static const material.Color darkBlue = material.Color(0xFF084298);

  @override
  material.Widget build(material.BuildContext context) {
    final screenWidth = material.MediaQuery.sizeOf(context).width;

    final dialogWidth = screenWidth < 500 ? screenWidth * 0.90 : 430.0;

    return material.Dialog(
      backgroundColor: material.Colors.white,

      surfaceTintColor: material.Colors.white,

      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(24),
      ),

      child: material.ConstrainedBox(
        constraints: material.BoxConstraints(maxWidth: dialogWidth),

        child: material.SingleChildScrollView(
          child: material.Padding(
            padding: const material.EdgeInsets.fromLTRB(24, 28, 24, 24),

            child: material.Column(
              mainAxisSize: material.MainAxisSize.min,

              children: [
                // ==================================================
                // ICON
                // ==================================================
                material.Container(
                  width: 70,
                  height: 70,

                  decoration: material.BoxDecoration(
                    color: bisBlue.withValues(alpha: 0.10),

                    shape: material.BoxShape.circle,
                  ),

                  child: const material.Icon(
                    material.Icons.verified_user_outlined,

                    size: 38,

                    color: bisBlue,
                  ),
                ),

                const material.SizedBox(height: 18),

                // ==================================================
                // TITLE
                // ==================================================
                const material.Text(
                  'Welcome to BIS Saathi',

                  textAlign: material.TextAlign.center,

                  style: material.TextStyle(
                    fontSize: 23,

                    fontWeight: material.FontWeight.w800,

                    color: darkBlue,
                  ),
                ),

                const material.SizedBox(height: 10),

                // ==================================================
                // DESCRIPTION
                // ==================================================
                const material.Text(
                  'Continue as a guest to explore BIS Saathi, '
                  'or login to access your account and all features.',

                  textAlign: material.TextAlign.center,

                  style: material.TextStyle(
                    fontSize: 14,

                    height: 1.5,

                    color: material.Color(0xFF667085),
                  ),
                ),

                const material.SizedBox(height: 24),

                // ==================================================
                // LOGIN
                // ==================================================
                material.SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: material.FilledButton.icon(
                    onPressed: onLogin,

                    icon: const material.Icon(material.Icons.login_rounded),

                    label: const material.Text(
                      'Login',
                      style: material.TextStyle(
                        fontSize: 15,
                        fontWeight: material.FontWeight.w700,
                      ),
                    ),

                    style: material.FilledButton.styleFrom(
                      backgroundColor: bisBlue,

                      foregroundColor: material.Colors.white,

                      shape: material.RoundedRectangleBorder(
                        borderRadius: material.BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const material.SizedBox(height: 12),

                // ==================================================
                // SIGN UP
                // ==================================================
                material.SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: material.OutlinedButton.icon(
                    onPressed: onSignUp,

                    icon: const material.Icon(
                      material.Icons.person_add_alt_1_rounded,
                    ),

                    label: const material.Text(
                      'Create Account / Sign Up',

                      style: material.TextStyle(
                        fontSize: 15,
                        fontWeight: material.FontWeight.w700,
                      ),
                    ),

                    style: material.OutlinedButton.styleFrom(
                      foregroundColor: darkBlue,

                      side: const material.BorderSide(
                        color: material.Color(0xFFD7DFEC),
                      ),

                      shape: material.RoundedRectangleBorder(
                        borderRadius: material.BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const material.SizedBox(height: 12),

                // ==================================================
                // GUEST
                // ==================================================
                material.SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: material.TextButton.icon(
                    onPressed: onContinueAsGuest,

                    icon: const material.Icon(
                      material.Icons.person_outline_rounded,
                    ),

                    label: const material.Text(
                      'Continue as Guest',

                      style: material.TextStyle(
                        fontSize: 15,
                        fontWeight: material.FontWeight.w700,
                      ),
                    ),

                    style: material.TextButton.styleFrom(
                      foregroundColor: material.Color(0xFF475467),

                      shape: material.RoundedRectangleBorder(
                        borderRadius: material.BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const material.SizedBox(height: 16),

                // ==================================================
                // SECURITY
                // ==================================================
                const material.Row(
                  mainAxisAlignment: material.MainAxisAlignment.center,

                  children: [
                    material.Icon(
                      material.Icons.lock_outline_rounded,

                      size: 14,

                      color: material.Color(0xFF98A2B3),
                    ),

                    material.SizedBox(width: 6),

                    material.Text(
                      'Secure access to your BIS Saathi account',

                      style: material.TextStyle(
                        fontSize: 11.5,

                        color: material.Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH LOADING SCREEN
// ============================================================

class _AuthLoadingScreen extends material.StatelessWidget {
  const _AuthLoadingScreen();

  @override
  material.Widget build(material.BuildContext context) {
    return const material.Scaffold(
      backgroundColor: material.Color(0xFFF7F9FC),

      body: material.Center(
        child: material.Column(
          mainAxisSize: material.MainAxisSize.min,

          children: [
            material.SizedBox(
              width: 42,
              height: 42,

              child: material.CircularProgressIndicator(
                strokeWidth: 3,

                color: material.Color(0xFF0B5ED7),
              ),
            ),

            material.SizedBox(height: 20),

            material.Text(
              'Loading BIS Saathi...',

              style: material.TextStyle(
                fontSize: 15,

                color: material.Color(0xFF5F6877),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN APPLICATION SHELL
// ============================================================

class MainApplicationShell extends material.StatelessWidget {
  final Map<String, dynamic>? user;

  final material.VoidCallback onLogout;

  const MainApplicationShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  // ==========================================================
  // GET ROLE
  // ==========================================================

  String _getRole() {
    if (user == null) {
      return '';
    }

    final dynamic roleValue = user!['role'];

    if (roleValue == null) {
      return '';
    }

    return roleValue.toString().trim().toLowerCase();
  }

  // ==========================================================
  // CHECK ADMIN
  // ==========================================================

  bool _isAdmin() {
    final role = _getRole();

    return role == 'admin' || role == 'administrator';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  material.Widget build(material.BuildContext context) {
    // --------------------------------------------------------
    // ADMIN
    // --------------------------------------------------------

    if (_isAdmin()) {
      return AdminScreen(onLogout: onLogout);
    }

    // --------------------------------------------------------
    // NORMAL USER
    // --------------------------------------------------------

    return LanguageScope(
      child: ResponsiveShell(
        home: const HomeScreen(),

        assistant: const AssistantScreen(),

        standards: const StandardsScreen(),

        compliance: const ComplianceScreen(),

        services: const ServicesScreen(),

        profile: ProfileScreen(onLogout: onLogout),
      ),
    );
  }
}
