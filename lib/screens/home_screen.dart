import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color bisBlue = Color(0xFF0B5ED7);
  static const Color darkBlue = Color(0xFF084298);
  static const Color deepBlue = Color(0xFF062B6F);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color background = Color(0xFFF6F9FE);
  static const Color borderColor = Color(0xFFE1E8F3);
  static const Color textSecondary = Color(0xFF667085);
  static const Color green = Color(0xFF16845B);
  static const Color orange = Color(0xFFF28C28);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _entryController.forward();
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Animation<double> _entryAnimation(double start, double end) {
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _reveal({
    required Widget child,
    required double start,
    required double end,
    double distance = 22,
  }) {
    final animation = _entryAnimation(start, end);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, distance * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HomeScreen.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < 600) {
            return _buildMobileLayout(context);
          }

          if (width < 1000) {
            return _buildTabletLayout(context);
          }

          return _buildDesktopLayout(context);
        },
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(
            start: 0.00,
            end: 0.35,
            distance: 26,
            child: _buildMobileHero(context),
          ),
          const SizedBox(height: 18),
          _reveal(start: 0.15, end: 0.45, child: _buildMobileAskCard(context)),
          const SizedBox(height: 22),
          _reveal(start: 0.25, end: 0.55, child: _buildMobileTrustRow()),
          const SizedBox(height: 28),
          _reveal(
            start: 0.35,
            end: 0.65,
            child: _buildSectionTitle(
              'Explore BIS Saathi',
              'Everything you need for standards and BIS services.',
              mobile: true,
            ),
          ),
          const SizedBox(height: 14),
          _reveal(
            start: 0.42,
            end: 0.72,
            child: _buildMobileFeatureCards(context),
          ),
          const SizedBox(height: 28),
          _reveal(
            start: 0.50,
            end: 0.80,
            child: _buildSectionTitle(
              'Quick Access',
              'Jump directly to a BIS tool.',
              mobile: true,
            ),
          ),
          const SizedBox(height: 14),
          _reveal(
            start: 0.58,
            end: 0.88,
            child: _buildQuickActions(context, false),
          ),
          const SizedBox(height: 28),
          _reveal(
            start: 0.65,
            end: 0.93,
            child: _buildBISInformationCard(false),
          ),
          const SizedBox(height: 16),
          _reveal(
            start: 0.70,
            end: 0.97,
            child: _buildOfficialSourcesCard(context),
          ),
          const SizedBox(height: 16),
          _buildDisclaimer(),
          const SizedBox(height: 22),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2F7FF), Color(0xFFE8F1FF), Color(0xFFF9FBFF)],
        ),
        border: Border.all(color: const Color(0xFFD8E6F8)),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.bisBlue.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -65,
            child: _buildGlowCircle(
              180,
              HomeScreen.bisBlue.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAiBadge(),
              const SizedBox(height: 17),
              const Text(
                'BIS Saathi',
                style: TextStyle(
                  color: HomeScreen.bisBlue,
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your intelligent companion for\nIndian Standards & BIS Services.',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ask questions, find standards, check compliance '
                'and explore BIS services from one place.',
                style: TextStyle(
                  color: HomeScreen.textSecondary,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              _buildMobileAiVisual(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAskCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/assistant');
        },
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFD5E3F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: HomeScreen.lightBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: HomeScreen.bisBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask BIS Saathi',
                      style: TextStyle(
                        color: Color(0xFF172B4D),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ask anything about BIS',
                      style: TextStyle(
                        color: HomeScreen.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: HomeScreen.bisBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTrustRow() {
    final items = [
      const _MiniTrust(icon: Icons.auto_awesome, title: 'AI'),
      const _MiniTrust(icon: Icons.menu_book_outlined, title: 'Standards'),
      const _MiniTrust(icon: Icons.fact_check_outlined, title: 'Compliance'),
      const _MiniTrust(icon: Icons.verified_outlined, title: 'Official'),
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          return _MiniTrustCard(data: items[index]);
        },
      ),
    );
  }

  Widget _buildMobileAiVisual() {
    return Center(
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final wave = math.sin(_floatController.value * math.pi * 2);

          return Transform.translate(offset: Offset(0, wave * 3), child: child);
        },
        child: SizedBox(
          width: 190,
          height: 145,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HomeScreen.bisBlue.withValues(alpha: 0.055),
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeScreen.bisBlue.withValues(alpha: 0.14),
                  ),
                ),
              ),
              _buildMobileFloatingIcon(
                Icons.search,
                const Alignment(-0.92, -0.35),
              ),
              _buildMobileFloatingIcon(
                Icons.verified_outlined,
                const Alignment(0.90, -0.30),
              ),
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2679E9), Color(0xFF084298)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HomeScreen.bisBlue.withValues(alpha: 0.28),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 39,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFloatingIcon(IconData icon, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE7F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: HomeScreen.bisBlue, size: 19),
      ),
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(start: 0, end: 0.4, child: _buildHero(context, false)),
          const SizedBox(height: 28),
          _reveal(start: 0.2, end: 0.55, child: _buildTrustStrip(false)),
          const SizedBox(height: 32),
          _reveal(
            start: 0.3,
            end: 0.65,
            child: _buildSectionTitle(
              'Everything you need from BIS Saathi',
              'One intelligent workspace for Indian Standards, compliance and BIS services.',
            ),
          ),
          const SizedBox(height: 16),
          _reveal(
            start: 0.4,
            end: 0.75,
            child: _buildFeatureGrid(context, false),
          ),
          const SizedBox(height: 34),
          _buildSectionTitle(
            'Quick Access',
            'Jump directly to the tools you use most.',
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context, false),
          const SizedBox(height: 34),
          _buildBISInformationCard(true),
          const SizedBox(height: 20),
          _buildOfficialSourcesCard(context),
          const SizedBox(height: 20),
          _buildDisclaimer(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reveal(
                start: 0,
                end: 0.40,
                distance: 32,
                child: _buildHero(context, true),
              ),
              const SizedBox(height: 30),
              _reveal(start: 0.18, end: 0.52, child: _buildTrustStrip(true)),
              const SizedBox(height: 38),
              _reveal(
                start: 0.27,
                end: 0.62,
                child: _buildSectionTitle(
                  'Everything you need from BIS Saathi',
                  'One intelligent workspace for Indian Standards, compliance and BIS services.',
                ),
              ),
              const SizedBox(height: 18),
              _reveal(
                start: 0.35,
                end: 0.72,
                child: _buildFeatureGrid(context, true),
              ),
              const SizedBox(height: 40),
              _reveal(
                start: 0.44,
                end: 0.80,
                child: _buildSectionTitle(
                  'Quick Access',
                  'Jump directly to the tools you use most.',
                ),
              ),
              const SizedBox(height: 18),
              _reveal(
                start: 0.50,
                end: 0.86,
                child: _buildQuickActions(context, true),
              ),
              const SizedBox(height: 40),
              _reveal(
                start: 0.58,
                end: 0.92,
                child: _buildBISInformationCard(true),
              ),
              const SizedBox(height: 22),
              _buildOfficialSourcesCard(context),
              const SizedBox(height: 22),
              _buildDisclaimer(),
              const SizedBox(height: 26),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP/TABLET HERO
  // ============================================================

  Widget _buildHero(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F8FF), Color(0xFFE7F0FF), Color(0xFFF9FBFF)],
        ),
        border: Border.all(color: const Color(0xFFD7E5F8)),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.bisBlue.withValues(alpha: 0.07),
            blurRadius: 35,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -100,
            child: _buildGlowCircle(
              280,
              HomeScreen.bisBlue.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -130,
            child: _buildGlowCircle(
              300,
              const Color(0xFF4FA5FF).withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWide ? 40 : 28),
            child: isWide
                ? Row(
                    children: [
                      Expanded(flex: 6, child: _buildHeroText(context)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildDesktopHeroVisual()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroText(context),
                      const SizedBox(height: 24),
                      Center(child: _buildDesktopHeroVisual()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiBadge(),
        const SizedBox(height: 17),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'BIS ',
                style: TextStyle(
                  color: HomeScreen.deepBlue,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1.7,
                ),
              ),
              TextSpan(
                text: 'Saathi',
                style: TextStyle(
                  color: HomeScreen.bisBlue,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your intelligent companion for\nIndian Standards & BIS Services.',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ask questions, discover standards, understand certification '
          'requirements, check compliance and explore BIS services — '
          'all from one intelligent platform.',
          style: TextStyle(
            color: HomeScreen.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 23),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildPrimaryButton(
              label: 'Ask BIS Saathi',
              icon: Icons.auto_awesome,
              onPressed: () {
                Navigator.pushNamed(context, '/assistant');
              },
            ),
            _buildSecondaryButton(
              label: 'Find a Standard',
              icon: Icons.search,
              onPressed: () {
                Navigator.pushNamed(context, '/standards');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: const [
            _HeroTrustItem(icon: Icons.verified_outlined, text: 'BIS-focused'),
            _HeroTrustItem(icon: Icons.bolt_outlined, text: 'AI-assisted'),
            _HeroTrustItem(icon: Icons.security_outlined, text: 'Source-aware'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeroVisual() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final wave = math.sin(_floatController.value * math.pi * 2);

        return Transform.translate(offset: Offset(0, wave * 5), child: child);
      },
      child: SizedBox(
        width: 330,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HomeScreen.bisBlue.withValues(alpha: 0.045),
              ),
            ),
            Container(
              width: 215,
              height: 215,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: HomeScreen.bisBlue.withValues(alpha: 0.16),
                ),
              ),
            ),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: HomeScreen.bisBlue.withValues(alpha: 0.09),
                ),
              ),
            ),
            _buildHeroFloatingIcon(Icons.search, const Alignment(-0.88, -0.40)),
            _buildHeroFloatingIcon(
              Icons.verified_outlined,
              const Alignment(0.88, -0.35),
            ),
            _buildHeroFloatingIcon(
              Icons.fact_check_outlined,
              const Alignment(-0.73, 0.66),
            ),
            _buildHeroFloatingIcon(
              Icons.menu_book_outlined,
              const Alignment(0.73, 0.66),
            ),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2679E9), Color(0xFF084298)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: HomeScreen.bisBlue.withValues(alpha: 0.28),
                    blurRadius: 32,
                    spreadRadius: 3,
                    offset: const Offset(0, 13),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFD9E5F5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: HomeScreen.green),
                    SizedBox(width: 7),
                    Text(
                      'BIS Saathi is ready',
                      style: TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMON HERO ELEMENTS
  // ============================================================

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD4E2F5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 15, color: HomeScreen.bisBlue),
          SizedBox(width: 7),
          Text(
            'AI-POWERED BIS ASSISTANT',
            style: TextStyle(
              color: HomeScreen.bisBlue,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [HomeScreen.bisBlue, HomeScreen.darkBlue],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: HomeScreen.bisBlue.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9CDE8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: HomeScreen.darkBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: HomeScreen.darkBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFloatingIcon(IconData icon, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 47,
        height: 47,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDCE7F5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 13,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: HomeScreen.bisBlue, size: 22),
      ),
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ============================================================
  // TRUST STRIP
  // ============================================================

  Widget _buildTrustStrip(bool isWide) {
    final items = [
      const _TrustData(
        icon: Icons.auto_awesome,
        title: 'AI Assistance',
        subtitle: 'Ask questions naturally',
        color: HomeScreen.bisBlue,
      ),
      const _TrustData(
        icon: Icons.menu_book_outlined,
        title: 'Indian Standards',
        subtitle: 'Discover relevant standards',
        color: HomeScreen.darkBlue,
      ),
      const _TrustData(
        icon: Icons.fact_check_outlined,
        title: 'Compliance',
        subtitle: 'Build practical checklists',
        color: HomeScreen.green,
      ),
      const _TrustData(
        icon: Icons.verified_outlined,
        title: 'Official Sources',
        subtitle: 'Verify important information',
        color: HomeScreen.orange,
      ),
    ];

    if (!isWide) {
      return SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(width: 205, child: _TrustCard(data: items[index]));
          },
        ),
      );
    }

    return Row(
      children: [
        for (int index = 0; index < items.length; index++) ...[
          Expanded(child: _TrustCard(data: items[index])),
          if (index < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    bool mobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: mobile ? 21 : 25,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF16233B),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: HomeScreen.textSecondary,
            fontSize: mobile ? 11.5 : 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================

  Widget _buildFeatureGrid(BuildContext context, bool isWide) {
    final cards = [
      const _FeatureData(
        icon: Icons.smart_toy_outlined,
        title: 'Ask BIS Saathi',
        description:
            'Get AI-assisted answers about BIS standards, certification and services.',
        route: '/assistant',
        accent: HomeScreen.bisBlue,
      ),
      const _FeatureData(
        icon: Icons.search_outlined,
        title: 'Find Standards',
        description:
            'Search Indian Standards by product, IS number, category or industry.',
        route: '/standards',
        accent: HomeScreen.darkBlue,
      ),
      const _FeatureData(
        icon: Icons.fact_check_outlined,
        title: 'Check Compliance',
        description:
            'Understand product requirements and generate a practical checklist.',
        route: '/compliance',
        accent: HomeScreen.green,
      ),
      const _FeatureData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Document Q&A',
        description:
            'Upload a BIS document and ask questions about the information inside it.',
        route: '/document-qa',
        accent: HomeScreen.orange,
      ),
    ];

    if (!isWide) {
      return Column(
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.15,
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

  // ============================================================
  // MOBILE FEATURES
  // ============================================================

  Widget _buildMobileFeatureCards(BuildContext context) {
    final cards = [
      const _FeatureData(
        icon: Icons.smart_toy_outlined,
        title: 'Ask BIS Saathi',
        description:
            'Get AI-assisted answers about BIS standards, certification and services.',
        route: '/assistant',
        accent: HomeScreen.bisBlue,
      ),
      const _FeatureData(
        icon: Icons.search_outlined,
        title: 'Find Standards',
        description:
            'Search Indian Standards by product, IS number, category or industry.',
        route: '/standards',
        accent: HomeScreen.darkBlue,
      ),
      const _FeatureData(
        icon: Icons.fact_check_outlined,
        title: 'Check Compliance',
        description:
            'Understand product requirements and generate a practical checklist.',
        route: '/compliance',
        accent: HomeScreen.green,
      ),
      const _FeatureData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Document Q&A',
        description:
            'Upload a BIS document and ask questions about the information inside it.',
        route: '/document-qa',
        accent: HomeScreen.orange,
      ),
    ];

    return Column(
      children: cards.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
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
  // QUICK ACCESS
  // ============================================================

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      const _QuickData(
        icon: Icons.search,
        title: 'Standard Finder',
        subtitle: 'Search IS standards',
        route: '/standards',
        accent: HomeScreen.bisBlue,
      ),
      const _QuickData(
        icon: Icons.fact_check_outlined,
        title: 'Compliance',
        subtitle: 'Check product requirements',
        route: '/compliance',
        accent: HomeScreen.green,
      ),
      const _QuickData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Document Q&A',
        subtitle: 'Ask questions from PDFs',
        route: '/document-qa',
        accent: HomeScreen.orange,
      ),
      const _QuickData(
        icon: Icons.business_outlined,
        title: 'BIS Services',
        subtitle: 'Access official services',
        route: '/services',
        accent: HomeScreen.darkBlue,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: isWide ? 1.45 : 1.22,
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

  Widget _buildBISInformationCard(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 27 : 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: HomeScreen.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBISInfoIcon(),
                const SizedBox(width: 17),
                Expanded(child: _buildBISInfoText()),
                const SizedBox(width: 20),
                _buildInfoBadge(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBISInfoIcon(),
                const SizedBox(height: 14),
                _buildBISInfoText(),
                const SizedBox(height: 14),
                _buildInfoBadge(),
              ],
            ),
    );
  }

  Widget _buildBISInfoIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: HomeScreen.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.account_balance_outlined,
        color: HomeScreen.bisBlue,
        size: 28,
      ),
    );
  }

  Widget _buildBISInfoText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bureau of Indian Standards',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF172B4D),
          ),
        ),
        SizedBox(height: 7),
        Text(
          'BIS Saathi is designed to help consumers and industry users '
          'navigate Indian Standards, certification information, '
          'compliance guidance and BIS services through a single '
          'intelligent interface.',
          style: TextStyle(
            color: HomeScreen.textSecondary,
            height: 1.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E7FA)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, color: HomeScreen.bisBlue, size: 17),
          SizedBox(width: 6),
          Text(
            'BIS-focused platform',
            style: TextStyle(
              color: HomeScreen.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFICIAL SOURCES
  // ============================================================

  Widget _buildOfficialSourcesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFF2F7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE8FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: HomeScreen.bisBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Built around official BIS information',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'BIS Saathi connects users with standards, compliance '
                  'guidance and official BIS services.',
                  style: TextStyle(
                    color: HomeScreen.textSecondary,
                    height: 1.4,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/services');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: HomeScreen.bisBlue,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 15),
                  label: const Text(
                    'Explore BIS Services',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
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
  // DISCLAIMER
  // ============================================================

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: HomeScreen.bisBlue, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'BIS Saathi provides AI-assisted information and guidance. '
              'Always verify important compliance decisions against '
              'current official BIS information.',
              style: TextStyle(
                color: HomeScreen.textSecondary,
                height: 1.4,
                fontSize: 11.2,
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
        padding: EdgeInsets.only(bottom: 5),
        child: Text(
          'BIS Saathi • AI-powered assistance for Indian Standards',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black45,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TRUST DATA
// ============================================================

class _TrustData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _TrustData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ============================================================
// TRUST CARD
// ============================================================

class _TrustCard extends StatelessWidget {
  final _TrustData data;

  const _TrustCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: HomeScreen.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeScreen.textSecondary,
                    fontSize: 9.8,
                    height: 1.2,
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

// ============================================================
// MINI TRUST
// ============================================================

class _MiniTrust {
  final IconData icon;
  final String title;

  const _MiniTrust({required this.icon, required this.title});
}

class _MiniTrustCard extends StatelessWidget {
  final _MiniTrust data;

  const _MiniTrustCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: HomeScreen.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: HomeScreen.bisBlue, size: 20),
          const SizedBox(height: 5),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO TRUST ITEM
// ============================================================

class _HeroTrustItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTrustItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: HomeScreen.bisBlue),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: HomeScreen.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
  final Color accent;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.accent,
  });
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard extends StatefulWidget {
  final _FeatureData data;
  final VoidCallback onTap;

  const _FeatureCard({required this.data, required this.onTap});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() {
              _pressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              _pressed = false;
            });
          },
          onTapUp: (_) {
            setState(() {
              _pressed = false;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HomeScreen.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.data.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.accent,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.data.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.data.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeScreen.textSecondary,
                          fontSize: 11.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUICK DATA
// ============================================================

class _QuickData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color accent;

  const _QuickData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accent,
  });
}

// ============================================================
// QUICK ACTION CARD
// ============================================================

class _QuickActionCard extends StatefulWidget {
  final _QuickData data;
  final VoidCallback onTap;

  const _QuickActionCard({required this.data, required this.onTap});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() {
              _pressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              _pressed = false;
            });
          },
          onTapUp: (_) {
            setState(() {
              _pressed = false;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeScreen.borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: widget.data.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.accent,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  widget.data.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.data.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeScreen.textSecondary,
                    fontSize: 9.5,
                    height: 1.2,
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
