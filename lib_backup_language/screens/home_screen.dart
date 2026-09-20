import 'package:flutter/material.dart';

// ============================================================
// BIS SAATHI COLORS
// These are top-level so every widget/class in this file
// can use them.
// ============================================================

const Color bisBlue = Color(0xFF0B5ED7);
const Color darkBlue = Color(0xFF084298);
const Color lightBlue = Color(0xFFEAF2FF);
const Color background = Color(0xFFF7F9FC);
const Color borderColor = Color(0xFFE2E7F0);
const Color textSecondary = Color(0xFF667085);

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: isWide ? 30 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(context, isWide),

                      const SizedBox(height: 38),

                      _buildSectionTitle(
                        'What can BIS Saathi help with?',
                        'AI-powered tools for standards, compliance and BIS services.',
                      ),

                      const SizedBox(height: 18),

                      _buildFeatureGrid(context, isWide),

                      const SizedBox(height: 40),

                      _buildSectionTitle(
                        'Quick Access',
                        'Frequently used BIS Saathi features.',
                      ),

                      const SizedBox(height: 18),

                      _buildQuickActions(context, isWide),

                      const SizedBox(height: 40),

                      _buildBISInformationCard(context, isWide),

                      const SizedBox(height: 24),

                      _buildOfficialSourcesCard(context),

                      const SizedBox(height: 24),

                      _buildDisclaimer(),

                      const SizedBox(height: 30),

                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 44 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFF2F6FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Color(0xFFDCE8FA)),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: _heroText(context)),
                const SizedBox(width: 40),
                Expanded(child: _heroVisual()),
              ],
            )
          : _heroText(context),
    );
  }

  // ============================================================
  // HERO TEXT
  // ============================================================

  Widget _heroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFDCE8FA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 15, color: bisBlue),
              SizedBox(width: 7),
              Text(
                'AI-Powered BIS Assistant',
                style: TextStyle(
                  color: bisBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'BIS Saathi',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: bisBlue,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Your intelligent assistant for Indian Standards and BIS Services',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: Color(0xFF202124),
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Find standards, understand certification requirements, '
          'check compliance and ask questions about BIS documents — '
          'all in one place.',
          style: TextStyle(fontSize: 15, color: textSecondary, height: 1.6),
        ),

        const SizedBox(height: 26),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/assistant');
              },
              style: FilledButton.styleFrom(
                backgroundColor: bisBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(
                'Ask BIS Saathi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/standards');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: darkBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                side: const BorderSide(color: Color(0xFF9BB9E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                'Find a Standard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // HERO VISUAL
  // ============================================================

  Widget _heroVisual() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFDCE8FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: bisBlue,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: bisBlue.withValues(alpha: 0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Ask • Find • Check',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),

              const SizedBox(height: 5),

              const Text(
                'One BIS companion',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF202124),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE GRID
  // ============================================================

  Widget _buildFeatureGrid(BuildContext context, bool isWide) {
    final cards = [
      _FeatureData(
        icon: Icons.smart_toy_outlined,
        title: 'Ask Questions',
        description:
            'Get AI-assisted answers about BIS standards, certification and services.',
        route: '/assistant',
      ),
      _FeatureData(
        icon: Icons.search_outlined,
        title: 'Find Standards',
        description:
            'Search Indian Standards by product, IS number, category or industry.',
        route: '/standards',
      ),
      _FeatureData(
        icon: Icons.fact_check_outlined,
        title: 'Check Compliance',
        description:
            'Understand product compliance and generate a practical checklist.',
        route: '/compliance',
      ),
      _FeatureData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Document Q&A',
        description:
            'Upload a PDF and ask questions about the information inside it.',
        route: '/document-qa',
      ),
    ];

    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.35,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];

          return _FeatureCard(
            data: card,
            onTap: () {
              Navigator.pushNamed(context, card.route);
            },
          );
        },
      );
    }

    return Column(
      children: cards.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FeatureCard(
            data: card,
            onTap: () {
              Navigator.pushNamed(context, card.route);
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      _QuickData(
        icon: Icons.search,
        title: 'Standard Finder',
        subtitle: 'Search IS standards',
        route: '/standards',
      ),
      _QuickData(
        icon: Icons.fact_check_outlined,
        title: 'Compliance',
        subtitle: 'Check product requirements',
        route: '/compliance',
      ),
      _QuickData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Document Q&A',
        subtitle: 'Ask questions from PDFs',
        route: '/document-qa',
      ),
      _QuickData(
        icon: Icons.business_outlined,
        title: 'BIS Services',
        subtitle: 'Access official services',
        route: '/services',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 1.45 : 1.25,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];

        return _QuickActionCard(
          data: action,
          onTap: () {
            Navigator.pushNamed(context, action.route);
          },
        );
      },
    );
  }

  // ============================================================
  // BIS INFORMATION
  // ============================================================

  Widget _buildBISInformationCard(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 28 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bisInfoIcon(),

                const SizedBox(width: 18),

                Expanded(child: _bisInfoText()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bisInfoIcon(),

                const SizedBox(height: 16),

                _bisInfoText(),
              ],
            ),
    );
  }

  Widget _bisInfoIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.account_balance_outlined,
        color: bisBlue,
        size: 29,
      ),
    );
  }

  Widget _bisInfoText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bureau of Indian Standards',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),

        SizedBox(height: 8),

        Text(
          'BIS Saathi is designed to help consumers and industry users '
          'navigate Indian Standards, certification information, '
          'compliance guidance and BIS services through a single '
          'intelligent interface.',
          style: TextStyle(color: textSecondary, height: 1.55, fontSize: 14),
        ),
      ],
    );
  }

  // ============================================================
  // OFFICIAL SOURCES
  // ============================================================

  Widget _buildOfficialSourcesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFDCE8FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: bisBlue,
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Built around official BIS information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                const Text(
                  'BIS Saathi connects users with standards, '
                  'compliance guidance and official BIS services.',
                  style: TextStyle(
                    color: textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/services');
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.arrow_forward, size: 17),
                  label: const Text('Explore BIS Services'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISCLAIMER
  // ============================================================

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDCE8FA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: bisBlue, size: 21),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'BIS Saathi provides AI-assisted information and guidance. '
              'Always verify important compliance decisions against '
              'current official BIS information.',
              style: TextStyle(
                color: textSecondary,
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'BIS Saathi • AI-powered assistance for Indian Standards',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black45, fontSize: 12),
        ),
      ),
    );
  }
}

// ============================================================
// FEATURE DATA
// ============================================================

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
}

// ============================================================
// QUICK DATA
// ============================================================

class _QuickData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _QuickData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  final VoidCallback onTap;

  const _FeatureCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: bisBlue, size: 29),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      data.description,
                      style: const TextStyle(
                        color: textSecondary,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUICK ACTION CARD
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final _QuickData data;
  final VoidCallback onTap;

  const _QuickActionCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, size: 25, color: bisBlue),
              ),

              const SizedBox(height: 10),

              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
