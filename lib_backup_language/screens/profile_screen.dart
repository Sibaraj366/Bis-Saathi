import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
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
                    child: const Icon(
                      Icons.person,
                      size: 36,
                      color: Color(0xFF0B5ED7),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIS Saathi User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Consumer / Industry User',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile settings coming soon.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

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
                    value: '12',
                    label: 'AI Questions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.search_outlined,
                    value: '8',
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
                    icon: Icons.description_outlined,
                    value: '3',
                    label: 'Documents',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    value: '5',
                    label: 'Checklist Items',
                  ),
                ),
              ],
            ),

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

            Container(
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
                      'BIS Saathi provides AI-assisted guidance. Always verify important compliance decisions using current official BIS information.',
                      style: TextStyle(height: 1.4, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

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

          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

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
