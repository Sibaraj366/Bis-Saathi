import 'package:flutter/material.dart' hide Text;
import '../services/app_language.dart';
import 'package:url_launcher/url_launcher.dart';

class StandardDetailsScreen extends StatelessWidget {
  final Map<String, String> standard;

  const StandardDetailsScreen({super.key, required this.standard});

  // ============================================================
  // SAFE VALUE HELPERS
  // ============================================================

  String _value(String key, {String fallback = 'Not available'}) {
    final value = standard[key];

    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  String get _isNumber {
    return _value('isNumber', fallback: 'IS number not available');
  }

  String get _product {
    return _value('product', fallback: 'Product not available');
  }

  String get _title {
    return _value('title', fallback: 'Standard title not available');
  }

  String get _category {
    return _value('category', fallback: 'Category not available');
  }

  String get _industry {
    return _value('industry', fallback: 'Industry not available');
  }

  String get _status {
    return _value(
      'status',
      fallback: 'Certification information not available',
    );
  }

  String get _information {
    return _value(
      'information',
      fallback:
          'Detailed standard information is not available in the current BIS knowledge base.',
    );
  }

  String get _officialSource {
    final source = standard['source'];

    if (source == null || source.trim().isEmpty) {
      return 'https://www.bis.gov.in/know-your-standard/?lang=en';
    }

    return source.trim();
  }

  // ============================================================
  // OFFICIAL BIS SOURCE
  // ============================================================

  Future<void> _openOfficialPage(BuildContext context) async {
    final uri = Uri.tryParse(_officialSource);

    if (uri == null) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The BIS source link is not valid.')),
      );

      return;
    }

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

  // ============================================================
  // ASK AI
  // ============================================================

  void _askAssistant(BuildContext context, String focus) {
    Navigator.pushNamed(
      context,
      '/assistant',
      arguments: {
        'initialMessage':
            '$focus for $_isNumber ($_product). '
            'Use BIS information and include the certification '
            'status and official source.',
      },
    );
  }

  // ============================================================
  // OPEN COMPLIANCE
  // ============================================================

  void _openCompliance(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/compliance',
      arguments: {'product': _product, 'autoGenerate': true},
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
          'Standard Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // STANDARD NUMBER
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4E3FA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indian Standard',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isNumber,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B5ED7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // TITLE
            // ==================================================
            Text(
              _title,
              softWrap: true,
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // STANDARD INFORMATION
            // ==================================================
            _infoCard(
              title: 'Standard Information',
              children: [
                _infoRow('Standard Number', _isNumber),
                _infoRow('Product', _product),
                _infoRow('Category', _category),
                _infoRow('Industry', _industry),
                _infoRow('Certification', _status),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // WHAT THIS STANDARD COVERS
            // ==================================================
            _infoCard(
              title: 'What this standard covers',
              children: [
                Text(
                  _information,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Manufacturers should verify the current applicable '
                  'scope, requirements, testing provisions and BIS '
                  'certification information before making a final '
                  'compliance decision.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================
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

            // ==================================================
            // OFFICIAL BIS SOURCE
            // ==================================================
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

                Material(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _openOfficialPage(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE8FA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            color: Color(0xFF0B5ED7),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _officialSource,
                              softWrap: true,
                              style: const TextStyle(
                                color: Color(0xFF0B5ED7),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.4,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  // ============================================================
  // INFO CARD
  // ============================================================

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

  // ============================================================
  // INFO ROW
  // ============================================================

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
              softWrap: true,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

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
