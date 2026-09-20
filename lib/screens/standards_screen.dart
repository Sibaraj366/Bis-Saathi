import 'package:flutter/material.dart' hide Text;

import '../services/api_service.dart';
import '../services/app_language.dart';
import 'standard_details_screen.dart';

class StandardsScreen extends StatefulWidget {
  const StandardsScreen({super.key});

  @override
  State<StandardsScreen> createState() => _StandardsScreenState();
}

class _StandardsScreenState extends State<StandardsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All Categories';
  String _selectedIndustry = 'All Industries';
  String _selectedSort = 'Relevance';

  List<Map<String, dynamic>> _standards = [];

  bool _isLoading = true;
  String? _errorMessage;

  bool _handledRouteArguments = false;

  // ============================================================
  // LANGUAGE
  // ============================================================

  String _translate(String value) {
    return AppLanguage.instance.t(value);
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // LOAD STANDARDS
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadStandards();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadStandards() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final standards = await ApiService.getStandards();

      if (!mounted) {
        return;
      }

      setState(() {
        _standards = standards;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _standards = [];
        _isLoading = false;
        _errorMessage =
            'Unable to load BIS standards. Please check the backend connection.';
      });
    }
  }

  // ============================================================
  // ROUTE ARGUMENTS
  // ============================================================

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

    final query = arguments['query'] ?? arguments['product'];

    if (query is String && query.trim().isNotEmpty) {
      _searchController.text = query.trim();
    }
  }

  // ============================================================
  // NORMALIZE BACKEND STANDARD
  // ============================================================

  Map<String, String> _normalizeStandard(Map<String, dynamic> item) {
    return {
      'product': _stringValue(
        item['product'],
        fallback: 'Product not available',
      ),
      'isNumber': _stringValue(
        item['is_number'] ?? item['isNumber'],
        fallback: 'IS number not available',
      ),
      'title': _stringValue(
        item['standard_title'] ?? item['title'],
        fallback: 'Standard title not available',
      ),
      'category': _stringValue(item['category'], fallback: 'General'),
      'industry': _stringValue(item['industry'], fallback: 'General'),
      'status': _stringValue(
        item['certification'] ?? item['status'],
        fallback: 'Certification information not available',
      ),
      'source': _stringValue(
        item['source'],
        fallback: 'https://www.bis.gov.in/know-your-standard/?lang=en',
      ),
      'information': _stringValue(
        item['information'],
        fallback:
            'Detailed information is not available in the current BIS knowledge base.',
      ),
    };
  }

  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  List<String> get _categories {
    final values = <String>{'All Categories'};

    for (final item in _standards) {
      final value = _stringValue(item['category']);

      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList();
  }

  List<String> get _industries {
    final values = <String>{'All Industries'};

    for (final item in _standards) {
      final value = _stringValue(item['industry']);

      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList();
  }

  // ============================================================
  // FILTERED RESULTS
  // ============================================================

  List<Map<String, dynamic>> get _filteredStandards {
    final query = _searchController.text.trim().toLowerCase();

    final results = _standards.where((item) {
      final product = _stringValue(item['product']).toLowerCase();

      final isNumber = _stringValue(
        item['is_number'] ?? item['isNumber'],
      ).toLowerCase();

      final title = _stringValue(
        item['standard_title'] ?? item['title'],
      ).toLowerCase();

      final keywords = _stringValue(item['keywords']).toLowerCase();

      final category = _stringValue(item['category']);

      final industry = _stringValue(item['industry']);

      final matchesSearch =
          query.isEmpty ||
          product.contains(query) ||
          isNumber.contains(query) ||
          title.contains(query) ||
          keywords.contains(query);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          category == _selectedCategory;

      final matchesIndustry =
          _selectedIndustry == 'All Industries' ||
          industry == _selectedIndustry;

      return matchesSearch && matchesCategory && matchesIndustry;
    }).toList();

    if (_selectedSort == 'A-Z') {
      results.sort(
        (a, b) => _stringValue(
          a['product'],
        ).toLowerCase().compareTo(_stringValue(b['product']).toLowerCase()),
      );
    } else if (_selectedSort == 'IS Number') {
      results.sort(
        (a, b) => _stringValue(
          a['is_number'] ?? a['isNumber'],
        ).compareTo(_stringValue(b['is_number'] ?? b['isNumber'])),
      );
    }

    return results;
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  Future<void> _openDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final normalized = _normalizeStandard(item);

    // Record that the user viewed a BIS standard.
    // Activity tracking must never prevent the standard
    // details page from opening.
    await ApiService.recordActivity('standard_view');

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StandardDetailsScreen(standard: normalized),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final results = _filteredStandards;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _translate('Standard Finder'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStandards,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(results),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent(List<Map<String, dynamic>> results) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ======================================================
        // PAGE TITLE
        // ======================================================
        Row(
          children: [
            const Icon(Icons.search, size: 32, color: Color(0xFF0B5ED7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _translate('Find Indian Standards'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          _translate(
            'Search by product, industry, standard number or keyword.',
          ),
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),

        const SizedBox(height: 20),

        // ======================================================
        // SEARCH BOX
        // ======================================================
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: _translate('Search standards...'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 14),

        // ======================================================
        // FILTERS
        // ======================================================
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildFilter(
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            _buildFilter(
              value: _selectedIndustry,
              items: _industries,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedIndustry = value;
                });
              },
            ),
            _buildFilter(
              value: _selectedSort,
              items: const ['Relevance', 'A-Z', 'IS Number'],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedSort = value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ======================================================
        // RESULT HEADER
        // ======================================================
        Row(
          children: [
            Expanded(
              child: Text(
                '${_translate('Search Results')} (${results.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: _clearSearch,
                child: Text(_translate('Clear')),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ======================================================
        // RESULTS
        // ======================================================
        if (results.isEmpty)
          _buildEmptyState()
        else
          ...results.map((item) => _standardResultCard(item)),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // STANDARD CARD
  // ============================================================

  Widget _standardResultCard(Map<String, dynamic> item) {
    final standard = _normalizeStandard(item);

    final isNumber = standard['isNumber'] ?? '';
    final title = standard['title'] ?? '';
    final product = standard['product'] ?? '';
    final category = standard['category'] ?? '';
    final status = standard['status'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          // ==================================================
          // HEADER ROW
          // ==================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF0B5ED7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isNumber,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B5ED7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ==================================================
          // TITLE
          // ==================================================
          Text(
            title,
            softWrap: true,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // PRODUCT
          // ==================================================
          Text(
            product,
            softWrap: true,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // TAGS
          // ==================================================
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _buildTag(category, Icons.category_outlined),
              _buildTag(status, Icons.verified_outlined),
            ],
          ),

          const SizedBox(height: 14),

          // ==================================================
          // VIEW DETAILS BUTTON
          // ==================================================
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                _openDetails(context, item);
              },
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: Text(_translate('View Details')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEAF2FF),
                foregroundColor: const Color(0xFF0B5ED7),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAG
  // ============================================================

  Widget _buildTag(String text, IconData icon) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E7F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF667085)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _buildFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            _translate('No standards found.'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _translate('Try another product, keyword or IS number.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_outlined, size: 60, color: Colors.black26),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Unable to load standards.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: _loadStandards,
            icon: const Icon(Icons.refresh),
            label: Text(_translate('Try Again')),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
