import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _standards = [
    {
      'product': 'PVC Insulated Electric Cables',
      'isNumber': 'IS 694:2010',
      'title':
          'Polyvinyl chloride insulated unsheathed and sheathed cables/cords with rigid and flexible conductor for rated voltages up to and including 1 100 V',
      'category': 'Electrical Products',
      'industry': 'Electrical',
      'status': 'Mandatory Certification',
      'source':
          'https://services.bis.gov.in/php/BIS_2.0/bisconnect/ISL/is_details?IDS=MTM4Mjk%3D',
    },
    {
      'product': 'Heavy Duty PVC Insulated Electric Cables',
      'isNumber': 'IS 1554 (Part 1):1988',
      'title':
          'Specification for PVC Insulated (Heavy Duty) Electric Cables Part 1 for Working Voltages up to and Including 1100 V',
      'category': 'Electrical Products',
      'industry': 'Electrical',
      'status': 'Compulsory Certification',
      'source':
          'https://www.bis.gov.in/product-certification/products-under-compulsory-certification/scheme-i-mark-scheme/?lang=en',
    },
    {
      'product': 'Heavy Duty PVC Insulated Electric Cables',
      'isNumber': 'IS 1554 (Part 2):1988',
      'title':
          'Specification for PVC Insulated (Heavy Duty) Electric Cables Part 2 for Working Voltages from 3.3 kV up to and Including 11 kV',
      'category': 'Electrical Products',
      'industry': 'Electrical',
      'status': 'Compulsory Certification',
      'source':
          'https://www.bis.gov.in/product-certification/products-under-compulsory-certification/scheme-i-mark-scheme/?lang=en',
    },
    {
      'product': 'Cement',
      'isNumber': 'IS 269:2015',
      'title': 'Ordinary Portland Cement — Specification',
      'category': 'Construction',
      'industry': 'Construction',
      'status': 'Compulsory Certification',
      'source':
          'https://www.bis.gov.in/product-certification/products-under-compulsory-certification/scheme-i-mark-scheme/?lang=en',
    },
    {
      'product': 'Cement',
      'isNumber': 'IS 1489 (Part 1):2015',
      'title':
          'Portland-Pozzolana Cement — Specification, Part 1: Fly Ash Based',
      'category': 'Construction',
      'industry': 'Construction',
      'status': 'Compulsory Certification',
      'source':
          'https://www.bis.gov.in/product-certification/products-under-compulsory-certification/scheme-i-mark-scheme/?lang=en',
    },
  ];

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

    final query = arguments['query'] ?? arguments['product'];

    if (query is String && query.trim().isNotEmpty) {
      _searchController.text = query.trim();
      setState(() {});
    }
  }

  List<Map<String, String>> get _filteredStandards {
    final query = _searchController.text.trim().toLowerCase();

    List<Map<String, String>> results = _standards.where((standard) {
      final matchesSearch =
          query.isEmpty ||
          standard['product']!.toLowerCase().contains(query) ||
          standard['isNumber']!.toLowerCase().contains(query) ||
          standard['title']!.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          standard['category'] == _selectedCategory;

      final matchesIndustry =
          _selectedIndustry == 'All Industries' ||
          standard['industry'] == _selectedIndustry;

      return matchesSearch && matchesCategory && matchesIndustry;
    }).toList();

    if (_selectedSort == 'A-Z') {
      results.sort((a, b) => a['product']!.compareTo(b['product']!));
    } else if (_selectedSort == 'IS Number') {
      results.sort((a, b) => a['isNumber']!.compareTo(b['isNumber']!));
    }

    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchStandards() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredStandards;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Standard Finder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, size: 32, color: Color(0xFF0B5ED7)),
                SizedBox(width: 10),
                Text(
                  'Find Indian Standards',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Search by product, industry, standard number or keyword.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchStandards(),
                    decoration: InputDecoration(
                      hintText: 'Search standards...',
                      prefixIcon: const Icon(Icons.search),
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
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _searchStandards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5ED7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilter(
                    value: _selectedCategory,
                    items: const [
                      'All Categories',
                      'Electrical Products',
                      'Construction',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildFilter(
                    value: _selectedIndustry,
                    items: const [
                      'All Industries',
                      'Electrical',
                      'Construction',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedIndustry = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildFilter(
                    value: _selectedSort,
                    items: const ['Relevance', 'A-Z', 'IS Number'],
                    onChanged: (value) {
                      setState(() {
                        _selectedSort = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results (${results.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 50,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No standards found.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Try another product, keyword or IS number.',
                            style: TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        return _standardResultCard(results[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
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

  Widget _standardResultCard(Map<String, String> standard) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standard['isNumber']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B5ED7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  standard['title']!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTag(standard['category']!),
                    _buildTag(standard['status']!),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  standard['product']!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StandardDetailsScreen(standard: standard),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B5ED7),
              side: const BorderSide(color: Color(0xFF0B5ED7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Details', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
