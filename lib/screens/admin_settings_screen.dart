import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminSettingsScreen({super.key, required this.onLogout});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _maintenanceMode = false;
  bool _allowUserRegistration = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from the admin panel?',
          ),
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
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onLogout();
    }
  }

  void _showAboutSystem() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF0B5ED7)),
              SizedBox(width: 10),
              Text('About BIS Saathi'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 42,
                            color: Color(0xFF0B5ED7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'BIS Saathi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI-Powered Intelligent Assistant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const _AboutTitle(
                    icon: Icons.info_outline,
                    title: 'About the Application',
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'BIS Saathi is an intelligent digital assistant designed to help industries, consumers and other users access information related to Indian Standards and BIS services through a convenient digital platform.',
                    style: TextStyle(color: Color(0xFF475467), height: 1.5),
                  ),

                  const SizedBox(height: 22),

                  const _AboutTitle(
                    icon: Icons.track_changes,
                    title: 'Purpose',
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'The application provides a centralized platform where users can explore standards, understand BIS-related services, perform compliance-related activities and interact with an AI assistant.',
                    style: TextStyle(color: Color(0xFF475467), height: 1.5),
                  ),

                  const SizedBox(height: 22),

                  const _AboutTitle(
                    icon: Icons.star_outline,
                    title: 'Key Features',
                  ),

                  const SizedBox(height: 10),

                  const _FeatureItem(
                    icon: Icons.smart_toy,
                    text: 'AI-powered assistance',
                  ),

                  const _FeatureItem(
                    icon: Icons.menu_book,
                    text: 'Indian Standards information',
                  ),

                  const _FeatureItem(
                    icon: Icons.miscellaneous_services,
                    text: 'BIS services information',
                  ),

                  const _FeatureItem(
                    icon: Icons.verified,
                    text: 'Compliance-related assistance',
                  ),

                  const _FeatureItem(
                    icon: Icons.description,
                    text: 'Document and document-question support',
                  ),

                  const _FeatureItem(
                    icon: Icons.people,
                    text: 'User and administrator management',
                  ),

                  const SizedBox(height: 22),

                  const _AboutTitle(
                    icon: Icons.account_balance,
                    title: 'About BIS',
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'The Bureau of Indian Standards (BIS) is India’s national standards body. BIS develops and promotes standards and provides various services related to standardization, conformity assessment, certification and consumer-related activities.',
                    style: TextStyle(color: Color(0xFF475467), height: 1.5),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E7F0)),
                    ),
                    child: const Column(
                      children: [
                        _InfoRow(label: 'Application', value: 'BIS Saathi'),
                        SizedBox(height: 10),
                        _InfoRow(label: 'Platform', value: 'Flutter'),
                        SizedBox(height: 10),
                        _InfoRow(label: 'Application Version', value: '1.0.0'),
                        SizedBox(height: 10),
                        _InfoRow(label: 'Panel', value: 'Administrator'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'BIS Saathi is intended to make access to BIS-related information and services simpler and more accessible through a modern digital interface.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'System Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'System Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Configure administrative options for BIS Saathi.',
            style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
          ),

          const SizedBox(height: 28),

          _SettingsSection(
            title: 'Application',
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });

                  _showMessage(
                    value
                        ? 'Notifications enabled.'
                        : 'Notifications disabled.',
                  );
                },
                title: const Text('Admin Notifications'),
                subtitle: const Text('Receive administrative notifications.'),
                secondary: const Icon(
                  Icons.notifications,
                  color: Color(0xFF0B5ED7),
                ),
              ),

              const Divider(height: 1),

              SwitchListTile(
                value: _allowUserRegistration,
                onChanged: (value) {
                  setState(() {
                    _allowUserRegistration = value;
                  });

                  _showMessage(
                    value
                        ? 'User registration enabled.'
                        : 'User registration disabled.',
                  );
                },
                title: const Text('Allow User Registration'),
                subtitle: const Text('Control whether new users can register.'),
                secondary: const Icon(
                  Icons.person_add,
                  color: Color(0xFF0B5ED7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SettingsSection(
            title: 'Maintenance',
            children: [
              SwitchListTile(
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });

                  _showMessage(
                    value
                        ? 'Maintenance mode enabled.'
                        : 'Maintenance mode disabled.',
                  );
                },
                title: const Text('Maintenance Mode'),
                subtitle: const Text(
                  'Enable this when the application is under maintenance.',
                ),
                secondary: Icon(
                  Icons.build,
                  color: _maintenanceMode
                      ? const Color(0xFFD92D20)
                      : const Color(0xFF0B5ED7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SettingsSection(
            title: 'System Information',
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF0B5ED7),
                ),
                title: const Text('About BIS Saathi'),
                subtitle: const Text(
                  'View BIS Saathi application and BIS information.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showAboutSystem,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SettingsSection(
            title: 'Administrator',
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFD92D20)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFD92D20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Sign out of the administrator account.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _confirmLogout,
              ),
            ],
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security, color: Color(0xFF0B5ED7)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Administrator settings are available only inside the protected admin area.',
                    style: TextStyle(color: Color(0xFF344054), height: 1.4),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7F0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AboutTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _AboutTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF0B5ED7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF0B5ED7)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF475467))),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
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
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF667085)),
          ),
        ),
      ],
    );
  }
}
