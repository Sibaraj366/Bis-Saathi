import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> initialStats;

  const AdminAnalyticsScreen({super.key, this.initialStats = const {}});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _stats = {};

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _stats = Map<String, dynamic>.from(widget.initialStats);

    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminService.getDashboard();

      if (!mounted) return;

      setState(() {
        _stats = result['stats'] is Map
            ? Map<String, dynamic>.from(result['stats'])
            : <String, dynamic>{};

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Application Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Analytics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Overview of BIS Saathi application usage and activity.',
                style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 28),

              if (_errorMessage != null)
                _ErrorCard(message: _errorMessage!, onRetry: _loadAnalytics),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              _buildSectionTitle('User Activity'),

              const SizedBox(height: 14),

              _AnalyticsGrid(
                cards: [
                  _AnalyticsCardData(
                    title: 'Total Users',
                    value: _stat('totalUsers'),
                    icon: Icons.people,
                  ),
                  _AnalyticsCardData(
                    title: 'Active Users',
                    value: _stat('activeUsers'),
                    icon: Icons.person,
                  ),
                  _AnalyticsCardData(
                    title: 'Inactive Users',
                    value: _stat('inactiveUsers'),
                    icon: Icons.person_off,
                  ),
                  _AnalyticsCardData(
                    title: 'Admin Users',
                    value: _stat('adminUsers'),
                    icon: Icons.admin_panel_settings,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildSectionTitle('Application Usage'),

              const SizedBox(height: 14),

              _AnalyticsGrid(
                cards: [
                  _AnalyticsCardData(
                    title: 'AI Questions',
                    value: _stat('aiQuestions'),
                    icon: Icons.smart_toy,
                  ),
                  _AnalyticsCardData(
                    title: 'Standards Viewed',
                    value: _stat('standardsViewed'),
                    icon: Icons.menu_book,
                  ),
                  _AnalyticsCardData(
                    title: 'Compliance Checks',
                    value: _stat('complianceChecks'),
                    icon: Icons.verified,
                  ),
                  _AnalyticsCardData(
                    title: 'Services Viewed',
                    value: _stat('servicesViewed'),
                    icon: Icons.miscellaneous_services,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildSectionTitle('Document Activity'),

              const SizedBox(height: 14),

              _AnalyticsGrid(
                cards: [
                  _AnalyticsCardData(
                    title: 'Documents',
                    value: _stat('documents'),
                    icon: Icons.description,
                  ),
                  _AnalyticsCardData(
                    title: 'Document Uploads',
                    value: _stat('documentUploads'),
                    icon: Icons.upload_file,
                  ),
                  _AnalyticsCardData(
                    title: 'Document Questions',
                    value: _stat('documentQuestions'),
                    icon: Icons.question_answer,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Container(
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
                    Icon(Icons.info_outline, color: Color(0xFF0B5ED7)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These statistics are loaded from the BIS Saathi backend admin dashboard API.',
                        style: TextStyle(color: Color(0xFF667085), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF172033),
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final List<_AnalyticsCardData> cards;

  const _AnalyticsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1000) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.0,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];

            return _AnalyticsCard(data: card);
          },
        );
      },
    );
  }
}

class _AnalyticsCardData {
  final String title;
  final int value;
  final IconData icon;

  const _AnalyticsCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _AnalyticsCard extends StatelessWidget {
  final _AnalyticsCardData data;

  const _AnalyticsCard({required this.data});

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
            child: Icon(data.icon, color: const Color(0xFF0B5ED7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

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
