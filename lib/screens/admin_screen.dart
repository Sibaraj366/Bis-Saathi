import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminScreen({super.key, required this.onLogout});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic> _stats = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ==========================================================
  // LOAD DASHBOARD
  // ==========================================================

  Future<void> _loadDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminService.getDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = result['stats'] is Map
            ? Map<String, dynamic>.from(result['stats'])
            : <String, dynamic>{};

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ==========================================================
  // CLEAN ERROR
  // ==========================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ==========================================================
  // GET STAT
  // ==========================================================

  int _stat(String key) {
    final value = _stats[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  // ==========================================================
  // USER MANAGEMENT
  // ==========================================================

  Future<void> _openUserManagement() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen()));

    if (mounted) {
      _loadDashboard();
    }
  }

  // ==========================================================
  // ANALYTICS
  // ==========================================================

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAnalyticsScreen(initialStats: _stats),
      ),
    );

    if (mounted) {
      _loadDashboard();
    }
  }

  // ==========================================================
  // SYSTEM SETTINGS
  // ==========================================================

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSettingsScreen(onLogout: widget.onLogout),
      ),
    );

    if (mounted) {
      _loadDashboard();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFF0B5ED7)),
            SizedBox(width: 10),
            Text(
              'BIS Saathi Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        onRefresh: _loadDashboard,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HEADER
              // ==================================================
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage BIS Saathi users, services and application activity.',
                style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ERROR
              // ==================================================
              if (_errorMessage != null)
                _ErrorBanner(message: _errorMessage!, onRetry: _loadDashboard),

              // ==================================================
              // LOADING / STATISTICS
              // ==================================================
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildStatistics(),

              const SizedBox(height: 32),

              // ==================================================
              // ADMINISTRATION
              // ==================================================
              const Text(
                'Administration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 16),

              // USER MANAGEMENT
              _AdminActionCard(
                icon: Icons.people,
                title: 'User Management',
                description:
                    'Search users, view accounts and manage user roles and status.',
                onTap: _openUserManagement,
              ),

              const SizedBox(height: 12),

              // SEARCH USERS
              _AdminActionCard(
                icon: Icons.search,
                title: 'Search Users',
                description: 'Find registered BIS Saathi users quickly.',
                onTap: _openUserManagement,
              ),

              const SizedBox(height: 12),

              // ANALYTICS
              _AdminActionCard(
                icon: Icons.bar_chart,
                title: 'Application Analytics',
                description:
                    'View AI, standards, compliance and document usage.',
                onTap: _openAnalytics,
              ),

              const SizedBox(height: 12),

              // SETTINGS
              _AdminActionCard(
                icon: Icons.settings,
                title: 'System Settings',
                description: 'Manage administrative application settings.',
                onTap: _openSettings,
              ),

              const SizedBox(height: 32),

              // ==================================================
              // SECURITY
              // ==================================================
              _buildSecurityInformation(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1100) {
          columns = 4;
        } else if (width >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cards = [
          _StatCard(
            title: 'Total Users',
            value: _stat('totalUsers').toString(),
            icon: Icons.people,
          ),

          _StatCard(
            title: 'Active Users',
            value: _stat('activeUsers').toString(),
            icon: Icons.person,
          ),

          _StatCard(
            title: 'Inactive Users',
            value: _stat('inactiveUsers').toString(),
            icon: Icons.person_off,
          ),

          _StatCard(
            title: 'Admin Users',
            value: _stat('adminUsers').toString(),
            icon: Icons.admin_panel_settings,
          ),

          _StatCard(
            title: 'AI Questions',
            value: _stat('aiQuestions').toString(),
            icon: Icons.smart_toy,
          ),

          _StatCard(
            title: 'Standards Viewed',
            value: _stat('standardsViewed').toString(),
            icon: Icons.menu_book,
          ),

          _StatCard(
            title: 'Compliance Checks',
            value: _stat('complianceChecks').toString(),
            icon: Icons.verified,
          ),

          _StatCard(
            title: 'Documents',
            value: _stat('documents').toString(),
            icon: Icons.description,
          ),
        ];

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: cards,
        );
      },
    );
  }

  // ==========================================================
  // SECURITY INFORMATION
  // ==========================================================

  Widget _buildSecurityInformation() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(Icons.security, color: Color(0xFF0B5ED7), size: 28),

          SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Administrator Access',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 6),

                Text(
                  'This dashboard is available only to accounts with the admin role. Admin API requests are also protected by the backend.',
                  style: TextStyle(color: Color(0xFF667085), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR BANNER
// ============================================================

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 24),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD92D20)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ),

          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: const Color(0xFF0B5ED7)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN ACTION CARD
// ============================================================

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7F0)),
          ),

          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: const Color(0xFF0B5ED7)),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
