import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StandardDetailsScreen extends StatelessWidget {
  final Map<String, String> standard;

  const StandardDetailsScreen({super.key, required this.standard});

  String get _officialSource {
    return standard['source'] ??
        'https://www.bis.gov.in/know-your-standard/?lang=en';
  }

  Future<void> _openOfficialPage(BuildContext context) async {
    final uri = Uri.parse(_officialSource);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the BIS source.')),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the BIS source.')),
      );
    }
  }

  void _askAssistant(BuildContext context, String focus) {
    Navigator.pushNamed(
      context,
      '/assistant',
      arguments: {
        'initialMessage':
            '$focus for ${standard['isNumber']} '
            '(${standard['product']}). Use BIS information and include '
            'the certification status and official source.',
      },
    );
  }

  void _openCompliance(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/compliance',
      arguments: {
        'product': standard['product'],
        'autoGenerate': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Standard Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              standard['isNumber']!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B5ED7),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              standard['title']!,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            _infoCard(
              title: 'Standard Information',
              children: [
                _infoRow('Standard Number', standard['isNumber']!),
                _infoRow('Product', standard['product']!),
                _infoRow('Category', standard['category']!),
                _infoRow('Industry', standard['industry']!),
                _infoRow('Certification', standard['status']!),
              ],
            ),

            const SizedBox(height: 16),

            _infoCard(
              title: 'What this standard covers',
              children: [
                Text(
                  'This Indian Standard specifies requirements for '
                  '${standard['product']!.toLowerCase()}. '
                  'Manufacturers should verify the applicable scope, '
                  'requirements, testing provisions and current BIS '
                  'certification information before making compliance '
                  'decisions.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _infoCard(
              title: 'Quick Actions',
              children: [
                _actionButton(
                  icon: Icons.smart_toy_outlined,
                  title: 'Ask AI about this standard',
                  onTap: () {
                    _askAssistant(
                      context,
                      'Explain this Indian Standard in simple terms',
                    );
                  },
                ),
                _actionButton(
                  icon: Icons.verified_outlined,
                  title: 'Certification requirements',
                  onTap: () {
                    _askAssistant(
                      context,
                      'Explain the BIS certification guidance',
                    );
                  },
                ),
                _actionButton(
                  icon: Icons.checklist_outlined,
                  title: 'Compliance checklist',
                  onTap: () {
                    _openCompliance(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _infoCard(
              title: 'Official BIS Source',
              children: [
                const Text(
                  'Verify the latest standard information directly '
                  'from the Bureau of Indian Standards.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openOfficialPage(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_new,
                        color: Color(0xFF0B5ED7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _officialSource,
                          style: const TextStyle(
                            color: Color(0xFF0B5ED7),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E8F8)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF0B5ED7),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: const Color(0xFF0B5ED7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
