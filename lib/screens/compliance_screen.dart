import 'package:flutter/material.dart' hide Text;
import '../services/app_language.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  final TextEditingController _productController = TextEditingController();

  Map<String, dynamic>? _selectedStandard;
  List<String> _checklist = [];
  final Set<int> _completedItems = {};

  bool _isLoading = false;
  String? _errorMessage;
  String? _summary;
  List<String> _sources = [];
  bool _handledRouteArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_handledRouteArguments) {
      return;
    }

    _handledRouteArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is! Map) {
      return;
    }

    final product = arguments['product'];
    final autoGenerate = arguments['autoGenerate'] == true;

    if (product is String && product.trim().isNotEmpty) {
      _productController.text = product.trim();

      if (autoGenerate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          _generateChecklist();
        });
      }
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  Future<void> _generateChecklist() async {
    final product = _productController.text.trim();

    if (product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedStandard = null;
      _checklist = [];
      _completedItems.clear();
      _summary = null;
      _sources = [];
    });

    try {
      final response = await ApiService.getCompliance(product, language: AppLanguage.instance.code);

      if (!mounted) {
        return;
      }

      if (response.success) {
        setState(() {
          _selectedStandard = response.standard;
          _checklist = response.checklist;
          _summary = response.summary;
          _sources = response.sources;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _checklist = response.checklist;
          _sources = response.sources;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to BIS Saathi server.';
      });
    }
  }

  int get _completedCount => _completedItems.length;

  double get _progress {
    if (_checklist.isEmpty) {
      return 0;
    }

    return _completedCount / _checklist.length;
  }

  Future<void> _openSource(String source) async {
    final uri = Uri.tryParse(source);

    if (uri == null) {
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the BIS source.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the BIS source.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compliance Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 32,
                  color: Color(0xFF0B5ED7),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Compliance Assistant',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Generate a product-specific BIS compliance checklist.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),

            const SizedBox(height: 22),

            const Text(
              'Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _productController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: AppLanguage.instance.t('Example: Cement or PVC Insulated Electric Cables'),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0E5EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0E5EC)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateChecklist,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? 'Generating...' : 'Generate Checklist',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5ED7),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF7FA9E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorCard(),
            ],

            if (_selectedStandard != null) ...[
              const SizedBox(height: 24),
              _buildStandardCard(),
            ],

            if (_summary != null) ...[
              const SizedBox(height: 20),
              _buildSummaryCard(),
            ],

            if (_checklist.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildChecklistHeader(),

              const SizedBox(height: 12),

              ...List.generate(
                _checklist.length,
                (index) => _buildChecklistItem(index, _checklist[index]),
              ),
            ],

            if (_sources.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSourcesCard(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2CACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard() {
    final standard = _selectedStandard!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E4FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF0B5ED7)),
              SizedBox(width: 8),
              Text(
                'Matched BIS Standard',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            standard['isNumber']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B5ED7),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            standard['title']?.toString() ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(standard['product']?.toString() ?? ''),
              _buildTag(standard['certification']?.toString() ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF0B5ED7)),
              SizedBox(width: 8),
              Text(
                'BIS Saathi Guidance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _summary ?? '',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance Checklist',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            '$_completedCount of ${_checklist.length} items completed',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE6EAF0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0B5ED7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(int index, String text) {
    final isCompleted = _completedItems.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFBFD3F2)
              : const Color(0xFFE0E5EC),
        ),
      ),
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _completedItems.add(index);
            } else {
              _completedItems.remove(index);
            }
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF0B5ED7),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isCompleted ? Colors.black45 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Color(0xFF0B5ED7)),
              SizedBox(width: 8),
              Text(
                'Official BIS Source',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ..._sources.map((source) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openSource(source),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            source,
                            style: const TextStyle(
                              color: Color(0xFF0B5ED7),
                              fontSize: 13,
                              height: 1.35,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF0B5ED7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
