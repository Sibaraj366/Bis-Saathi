import 'dart:async';

import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchTimer;

  List<Map<String, dynamic>> _users = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _roleFilter = '';
  String _statusFilter = '';

  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool? isActive;

      if (_statusFilter == 'active') {
        isActive = true;
      } else if (_statusFilter == 'inactive') {
        isActive = false;
      }

      final result = await AdminService.getUsers(
        search: _searchController.text,
        role: _roleFilter,
        isActive: isActive,
        limit: 100,
        offset: 0,
      );

      final rawUsers = result['users'];

      final users = rawUsers is List
          ? rawUsers
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _users = users;
        _totalUsers = _toInt(result['total']);
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _stringValue(Map<String, dynamic> user, String key) {
    return user[key]?.toString() ?? '';
  }

  bool _isActive(Map<String, dynamic> user) {
    final value = user['is_active'];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 450), _loadUsers);
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = _toInt(user['id']);

    if (userId <= 0) {
      return;
    }

    final currentStatus = _isActive(user);
    final name = _stringValue(user, 'full_name');

    final action = currentStatus ? 'deactivate' : 'activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(currentStatus ? 'Deactivate User' : 'Activate User'),
          content: Text('Are you sure you want to $action "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(currentStatus ? 'Deactivate' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AdminService.updateUser(userId: userId, isActive: !currentStatus);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus
                ? 'User deactivated successfully.'
                : 'User activated successfully.',
          ),
        ),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final userId = _toInt(user['id']);

    if (userId <= 0) {
      return;
    }

    final currentRole = _stringValue(user, 'role').toLowerCase();

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Change User Role'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop('user');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('User'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop('admin');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Administrator'),
              ),
            ),
          ],
        );
      },
    );

    if (selectedRole == null || selectedRole == currentRole) {
      return;
    }

    try {
      await AdminService.updateUser(userId: userId, role: selectedRole);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated successfully.')),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    final userId = _toInt(user['id']);

    if (userId <= 0) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final result = await AdminService.getUser(userId);

      if (!mounted) return;

      Navigator.of(context).pop();

      final userData = result['user'] is Map
          ? Map<String, dynamic>.from(result['user'])
          : user;

      final activity = result['activity'] is Map
          ? Map<String, dynamic>.from(result['activity'])
          : <String, dynamic>{};

      _showDetailsDialog(userData, activity);
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  void _showDetailsDialog(
    Map<String, dynamic> user,
    Map<String, dynamic> activity,
  ) {
    final name = _stringValue(user, 'full_name');
    final email = _stringValue(user, 'email');
    final role = _stringValue(user, 'role');
    final createdAt = _stringValue(user, 'created_at');
    final lastLogin = _stringValue(user, 'last_login');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name.isEmpty ? 'User Details' : name),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Email', value: email),
                  _DetailRow(label: 'Role', value: role),
                  _DetailRow(
                    label: 'Status',
                    value: _isActive(user) ? 'Active' : 'Inactive',
                  ),
                  _DetailRow(
                    label: 'Created',
                    value: createdAt.isEmpty ? 'Not available' : createdAt,
                  ),
                  _DetailRow(
                    label: 'Last Login',
                    value: lastLogin.isEmpty ? 'Never' : lastLogin,
                  ),
                  if (activity.isNotEmpty) ...[
                    const Divider(height: 28),
                    const Text(
                      'Activity Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...activity.entries.map(
                      (entry) => _DetailRow(
                        label: _formatLabel(entry.key),
                        value: entry.value.toString(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatLabel(String value) {
    final text = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      final first = match.group(1) ?? '';
      final second = match.group(2) ?? '';

      return '$first $second';
    });

    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.people, color: Color(0xFF0B5ED7)),
            SizedBox(width: 10),
            Text(
              'User Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRoleFilter()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatusFilter()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: _buildSearchField()),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _buildRoleFilter()),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _buildStatusFilter()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name or email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _loadUsers();
                },
                icon: const Icon(Icons.clear),
              ),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return DropdownButtonFormField<String>(
      value: _roleFilter,
      decoration: InputDecoration(
        labelText: 'Role',
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('All Roles')),
        DropdownMenuItem(value: 'user', child: Text('Users')),
        DropdownMenuItem(value: 'admin', child: Text('Administrators')),
      ],
      onChanged: (value) {
        setState(() {
          _roleFilter = value ?? '';
        });

        _loadUsers();
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('All Status')),
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: (value) {
        setState(() {
          _statusFilter = value ?? '';
        });

        _loadUsers();
      },
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFD92D20),
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadUsers, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.people_outline, size: 64, color: Color(0xFF98A2B3)),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No users found.',
                style: TextStyle(fontSize: 16, color: Color(0xFF667085)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _users.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Showing ${_users.length} of $_totalUsers users',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
              ),
            );
          }

          final user = _users[index - 1];

          return _UserCard(
            user: user,
            isActive: _isActive(user),
            onTap: () => _showUserDetails(user),
            onToggleStatus: () => _toggleUserStatus(user),
            onChangeRole: () => _changeRole(user),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onChangeRole;

  const _UserCard({
    required this.user,
    required this.isActive,
    required this.onTap,
    required this.onToggleStatus,
    required this.onChangeRole,
  });

  String _value(String key) {
    return user[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final name = _value('full_name');
    final email = _value('email');
    final role = _value('role');

    final initials = name.isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
              .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF2FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF0B5ED7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unnamed User' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          text: role == 'admin' ? 'Administrator' : 'User',
                          icon: role == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                        ),
                        _Badge(
                          text: isActive ? 'Active' : 'Inactive',
                          icon: isActive ? Icons.check_circle : Icons.cancel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Manage User',
                onSelected: (value) {
                  if (value == 'details') {
                    onTap();
                  } else if (value == 'status') {
                    onToggleStatus();
                  } else if (value == 'role') {
                    onChangeRole();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline),
                      title: Text('View Details'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isActive ? Icons.person_off : Icons.person_add,
                      ),
                      title: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'role',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('Change Role'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF667085)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475467)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475467),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ),
        ],
      ),
    );
  }
}
