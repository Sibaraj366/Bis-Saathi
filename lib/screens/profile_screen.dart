import 'package:flutter/material.dart' hide Text;

import '../services/api_service.dart';
import '../services/app_language.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;

  String _name = 'BIS Saathi User';
  String _email = '';
  String _role = 'user';
  String _language = 'English';

  int _aiQuestions = 0;
  int _standardsViewed = 0;
  int _complianceChecks = 0;
  int _documents = 0;
  int _documentUploads = 0;
  int _documentQuestions = 0;
  int _servicesViewed = 0;

  List<ConversationSummary> _recentConversations = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getCurrentUser(),
        ApiService.getActivity(),
        ApiService.getConversations(),
      ]);

      if (!mounted) {
        return;
      }

      final userData = results[0] as Map<String, dynamic>;

      final activityData = results[1] as Map<String, dynamic>;

      final conversations = results[2] as List<ConversationSummary>;

      final user = _extractUser(userData);
      final activity = _extractActivity(activityData);

      // ----------------------------------------------------------
      // IMPORTANT:
      // Sort by updatedAt so Recent Activity always shows the
      // latest conversations first.
      // ----------------------------------------------------------

      final sortedConversations = List<ConversationSummary>.from(conversations);

      sortedConversations.sort((a, b) {
        final aDate = DateTime.tryParse(a.updatedAt.toString());

        final bDate = DateTime.tryParse(b.updatedAt.toString());

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      setState(() {
        _name = _readString(
          user['full_name'] ?? user['fullName'] ?? user['name'],
          fallback: 'BIS Saathi User',
        );

        _email = _readString(user['email']);

        _role = _readString(user['role'], fallback: 'user');

        _language = _readString(
          user['preferred_language'] ??
              user['preferredLanguage'] ??
              user['language'],
          fallback: 'English',
        );

        _aiQuestions = _readInt(activity['aiQuestions']);

        _standardsViewed = _readInt(activity['standardsViewed']);

        _complianceChecks = _readInt(activity['complianceChecks']);

        _documents = _readInt(activity['documents']);

        _documentUploads = _readInt(activity['documentUploads']);

        _documentQuestions = _readInt(activity['documentQuestions']);

        _servicesViewed = _readInt(activity['servicesViewed']);

        _recentConversations = sortedConversations.take(5).toList();

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  // ============================================================
  // EXTRACT USER
  // ============================================================

  Map<String, dynamic> _extractUser(Map<String, dynamic> response) {
    final dynamic user = response['user'];

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return response;
  }

  // ============================================================
  // EXTRACT ACTIVITY
  // ============================================================

  Map<String, dynamic> _extractActivity(Map<String, dynamic> response) {
    final dynamic activity = response['activity'];

    if (activity is Map) {
      return Map<String, dynamic>.from(activity);
    }

    return response;
  }

  // ============================================================
  // READ STRING
  // ============================================================

  String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // READ INTEGER
  // ============================================================

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // FRIENDLY ERROR
  // ============================================================

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // ROLE LABEL
  // ============================================================

  String _roleLabel() {
    final role = _role.toLowerCase();

    if (role == 'admin' || role == 'administrator') {
      return 'Administrator';
    }

    return 'Consumer / Industry User';
  }

  // ============================================================
  // CONVERSATION TIME
  // ============================================================

  String _conversationTime(ConversationSummary conversation) {
    final raw = conversation.updatedAt.toString();

    if (raw.trim().isEmpty || raw == 'null') {
      return '';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    final local = parsed.toLocal();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(local.year, local.month, local.day);

    final difference = today.difference(date).inDays;

    if (difference == 0) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;

      final minute = local.minute.toString().padLeft(2, '0');

      final period = local.hour >= 12 ? 'PM' : 'AM';

      return 'Today, $hour:$minute $period';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference >= 2 && difference < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      return weekdays[local.weekday - 1];
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: const Text(
            'Password change is not available yet because the BIS Saathi '
            'backend does not currently provide a change-password API.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from BIS Saathi?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ApiService.logout();
    } catch (_) {
      // Ignore local logout errors.
      // The user should still be returned to login.
    }

    if (!mounted) {
      return;
    }

    widget.onLogout?.call();
  }

  // ============================================================
  // OPEN CONVERSATION
  // ============================================================

  void _openConversation(ConversationSummary conversation) {
    Navigator.pushNamed(
      context,
      '/assistant',
      arguments: {'conversationId': conversation.id.toString()},
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    AppLanguage.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),

            const SizedBox(height: 25),

            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 20),
            ],

            const Text(
              'Your BIS Activity',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.question_answer_outlined,
                    value: _aiQuestions.toString(),
                    label: 'AI Questions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.search_outlined,
                    value: _standardsViewed.toString(),
                    label: 'Standards Viewed',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.fact_check_outlined,
                    value: _complianceChecks.toString(),
                    label: 'Compliance Checks',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.description_outlined,
                    value: _documents.toString(),
                    label: 'Documents',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.upload_file_outlined,
                    value: _documentUploads.toString(),
                    label: 'PDF Uploads',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.question_answer_outlined,
                    value: _documentQuestions.toString(),
                    label: 'Document Questions',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.miscellaneous_services_outlined,
                    value: _servicesViewed.toString(),
                    label: 'Services Viewed',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 28),

            _buildRecentActivity(),

            const SizedBox(height: 28),

            const Text(
              'Quick Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            _DashboardAction(
              icon: Icons.smart_toy_outlined,
              title: 'AI Assistant',
              description:
                  'Ask questions about BIS standards and certification.',
              onTap: () {
                Navigator.pushNamed(context, '/assistant');
              },
            ),

            _DashboardAction(
              icon: Icons.search,
              title: 'Standard Finder',
              description: 'Search and explore Indian Standards.',
              onTap: () {
                Navigator.pushNamed(context, '/standards');
              },
            ),

            _DashboardAction(
              icon: Icons.fact_check_outlined,
              title: 'Compliance',
              description: 'Generate a product compliance checklist.',
              onTap: () {
                Navigator.pushNamed(context, '/compliance');
              },
            ),

            _DashboardAction(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Document Q&A',
              description: 'Upload a BIS PDF and ask questions.',
              onTap: () {
                Navigator.pushNamed(context, '/document-qa');
              },
            ),

            _DashboardAction(
              icon: Icons.miscellaneous_services_outlined,
              title: 'BIS Services',
              description: 'Access important official BIS services.',
              onTap: () {
                Navigator.pushNamed(context, '/services');
              },
            ),

            const SizedBox(height: 25),

            _buildInformationCard(),

            const SizedBox(height: 20),

            _buildLogoutButton(),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your latest BIS Saathi conversations.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            if (_recentConversations.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/assistant');
                },
                child: const Text('View All'),
              ),
          ],
        ),

        const SizedBox(height: 15),

        if (_recentConversations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E7F0)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 38,
                  color: Color(0xFF0B5ED7),
                ),
                SizedBox(height: 10),
                Text(
                  'No recent activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Start a conversation with BIS Saathi AI to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E7F0)),
            ),
            child: Column(
              children: List.generate(_recentConversations.length, (index) {
                final conversation = _recentConversations[index];

                return Column(
                  children: [
                    _RecentActivityTile(
                      conversation: conversation,
                      time: _conversationTime(conversation),
                      onTap: () {
                        _openConversation(conversation);
                      },
                    ),
                    if (index < _recentConversations.length - 1)
                      const Divider(height: 1, indent: 70, endIndent: 18),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final initial = _name.trim().isNotEmpty
        ? _name.trim()[0].toUpperCase()
        : 'B';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B5ED7),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(_email, style: const TextStyle(color: Colors.black54)),
                ],

                const SizedBox(height: 5),

                Text(
                  _roleLabel(),
                  style: const TextStyle(
                    color: Color(0xFF0B5ED7),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Language: $_language',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Change password',
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0CACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not load some profile information.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A2020),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _errorMessage ?? '',
                  style: const TextStyle(color: Color(0xFF7A2020)),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _loadProfile,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF0B5ED7)),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'BIS Saathi provides AI-assisted guidance. '
              'Always verify important compliance decisions '
              'using current official BIS information.',
              style: TextStyle(height: 1.4, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _logout,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout),
        label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0B5ED7), size: 28),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT ACTIVITY TILE
// ============================================================

class _RecentActivityTile extends StatelessWidget {
  final ConversationSummary conversation;
  final String time;
  final VoidCallback onTap;

  const _RecentActivityTile({
    required this.conversation,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF0B5ED7),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    conversation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD ACTION
// ============================================================

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0B5ED7)),
              ),

              const SizedBox(width: 14),

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

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
