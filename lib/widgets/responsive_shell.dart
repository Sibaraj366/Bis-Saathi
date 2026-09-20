import 'package:flutter/material.dart' hide Text;
import '../services/app_language.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget home;
  final Widget assistant;
  final Widget standards;
  final Widget compliance;
  final Widget services;
  final Widget profile;

  const ResponsiveShell({
    super.key,
    required this.home,
    required this.assistant,
    required this.standards,
    required this.compliance,
    required this.services,
    required this.profile,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color bisBlue = Color(0xFF0B5ED7);

  static const Color background = Color(0xFFF7F9FC);

  static const Color selectedBackground = Color(0xFFEAF2FF);

  static const Color borderColor = Color(0xFFE2E7F0);

  static const Color textSecondary = Color(0xFF667085);

  // ============================================================
  // CURRENT TAB
  // ============================================================

  int _selectedIndex = 0;

  // ============================================================
  // MOBILE NAVIGATION ITEMS
  // ============================================================

  final List<_NavigationItem> _navigationItems = const [
    _NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationItem(
      label: 'Assistant',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
    ),
    _NavigationItem(
      label: 'Standards',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
    ),
    _NavigationItem(
      label: 'Compliance',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    _NavigationItem(
      label: 'Services',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  // ============================================================
  // TAB CHANGE
  // ============================================================

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    AppLanguage.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return _buildDesktopLayout();
        }

        return _buildMobileLayout();
      },
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildMobileHeader(),

            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  widget.home,
                  widget.assistant,
                  widget.standards,
                  widget.compliance,
                  widget.services,
                  widget.profile,
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildMobileBottomNavigation(),
    );
  }

  // ============================================================
  // MOBILE HEADER
  // ============================================================

  Widget _buildMobileHeader() {
    return Container(
      height: 62,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // BIS ICON
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selectedBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: bisBlue,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          // TITLE
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIS Saathi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202124),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Smart BIS Assistant',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: textSecondary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // PROFILE BUTTON
          Material(
            color: selectedBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _onTabSelected(5);
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.person_outline, color: bisBlue, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE BOTTOM NAVIGATION
  // ============================================================

  Widget _buildMobileBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_navigationItems.length, (index) {
              final item = _navigationItems[index];

              final selected = index == _selectedIndex;

              return Expanded(
                child: _MobileNavigationButton(
                  item: item,
                  selected: selected,
                  onTap: () {
                    _onTabSelected(index);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: background,
      body: Row(
        children: [
          _buildDesktopSidebar(),

          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),

                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      widget.home,
                      widget.assistant,
                      widget.standards,
                      widget.compliance,
                      widget.services,
                      widget.profile,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP SIDEBAR
  // ============================================================

  Widget _buildDesktopSidebar() {
    return Container(
      width: 235,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // BRAND
          Container(
            height: 108,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selectedBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: bisBlue,
                    size: 31,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIS Saathi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202124),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Smart BIS Assistant',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // NAVIGATION
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _DesktopNavigationButton(
                    item: item,
                    selected: index == _selectedIndex,
                    onTap: () {
                      _onTabSelected(index);
                    },
                  ),
                );
              },
            ),
          ),

          // DISCLAIMER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFDCE8FA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: bisBlue, size: 18),

                  SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      'Verify important compliance '
                      'decisions against current '
                      'official BIS information.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP HEADER
  // ============================================================

  Widget _buildDesktopHeader() {
    return Container(
      height: 94,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bureau of Indian Standards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
          ),

          // LANGUAGE
          PopupMenuButton<String>(
            tooltip: 'Select language',
            onSelected: (value) => AppLanguage.instance.setLanguage(value),
            itemBuilder: (context) => AppLanguage.supported.map((value) {
              return PopupMenuItem<String>(
                value: value,
                child: Text(value == 'Hindi' ? 'हिंदी' : value == 'Marathi' ? 'मराठी' : 'English', style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(AppLanguage.instance.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 7),
                  const Icon(Icons.keyboard_arrow_down, color: textSecondary, size: 19),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // PROFILE
          Material(
            color: selectedBackground,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _onTabSelected(5);
              },
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.person_outline, color: bisBlue, size: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NAVIGATION ITEM
// ============================================================

class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// ============================================================
// MOBILE NAVIGATION BUTTON
// ============================================================

class _MobileNavigationButton extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileNavigationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              size: 21,
              color: selected
                  ? const Color(0xFF0B5ED7)
                  : const Color(0xFF475467),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? const Color(0xFF202124)
                  : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DESKTOP NAVIGATION BUTTON
// ============================================================

class _DesktopNavigationButton extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DesktopNavigationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected
                      ? const Color(0xFF0B5ED7)
                      : const Color(0xFF667085),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF0B5ED7)
                          : const Color(0xFF344054),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
