import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

// ============================================================
// SHARED BIS COLORS
// ============================================================

const Color bisBlue = Color(0xFF0B5ED7);
const Color backgroundColor = Color(0xFFF7F9FC);
const Color lightBlue = Color(0xFFEAF2FF);
const Color borderColor = Color(0xFFE2E7F0);
const Color textSecondary = Color(0xFF667085);

// ============================================================
// ASSISTANT SCREEN
// ============================================================

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // STATE
  // ============================================================

  String _currentQuestion = '';

  String _answer = '';

  List<String> _sources = [];

  bool _isLoading = false;

  bool _hasAskedQuestion = false;

  bool _handledRouteArguments = false;

  // ============================================================
  // LANGUAGE
  // ============================================================

  String _selectedLanguage = 'English';

  String get _languageLabel {
    switch (_selectedLanguage) {
      case 'Hindi':
        return 'हिंदी';
      case 'Marathi':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  // ============================================================
  // SUGGESTED QUESTIONS
  // ============================================================

  final List<String> _suggestedQuestions = [
    'What is IS 269:2015?',
    'What is BIS certification?',
    'How can I apply for BIS certification?',
    'What BIS standard applies to cement?',
  ];

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

    final initialMessage = arguments['initialMessage'];

    if (initialMessage is String && initialMessage.trim().isNotEmpty) {
      final message = initialMessage.trim();

      _messageController.text = message;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _sendMessage(message);
      });
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final message = (suggestedMessage ?? _messageController.text).trim();

    if (message.isEmpty || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _currentQuestion = message;
      _hasAskedQuestion = true;
      _isLoading = true;
      _answer = '';
      _sources = [];
    });

    final result = await ApiService.sendMessage(
      message,
      language: _selectedLanguage,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _answer = result.answer;
      _sources = result.sources;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  // ============================================================
  // LANGUAGE CHANGE
  // ============================================================

  void _changeLanguage(String language) {
    if (_selectedLanguage == language) {
      return;
    }

    setState(() {
      _selectedLanguage = language;
    });

    if (_hasAskedQuestion && _currentQuestion.trim().isNotEmpty) {
      _sendMessage(_currentQuestion);
    }
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // OPEN SOURCE
  // ============================================================

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

  // ============================================================
  // CLEAR CONVERSATION
  // ============================================================

  void _clearConversation() {
    setState(() {
      _messageController.clear();
      _currentQuestion = '';
      _answer = '';
      _sources = [];
      _hasAskedQuestion = false;
      _isLoading = false;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAssistantHeader(isWide),
                Expanded(
                  child: _hasAskedQuestion
                      ? _buildConversation(isWide)
                      : _buildWelcome(isWide),
                ),
                _buildMessageComposer(isWide),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildAssistantHeader(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 46 : 40,
            height: isWide ? 46 : 40,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: bisBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIS Saathi AI Assistant',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Indian Standards • Certification • BIS Services',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // ======================================================
          // LANGUAGE SELECTOR
          // ======================================================
          _buildLanguageSelector(),

          if (_hasAskedQuestion)
            IconButton(
              tooltip: 'New conversation',
              onPressed: _clearConversation,
              icon: const Icon(Icons.refresh),
              color: textSecondary,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE SELECTOR
  // ============================================================

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      tooltip: 'Select language',
      initialValue: _selectedLanguage,
      onSelected: _changeLanguage,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'English',
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: bisBlue),
                SizedBox(width: 10),
                Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'Hindi',
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: bisBlue),
                SizedBox(width: 10),
                Text('हिंदी', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'Marathi',
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: bisBlue),
                SizedBox(width: 10),
                Text('मराठी', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD5E5FA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 17, color: bisBlue),
            const SizedBox(width: 6),
            Text(
              _languageLabel,
              style: const TextStyle(
                color: bisBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: bisBlue),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME SCREEN
  // ============================================================

  Widget _buildWelcome(bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isWide ? 32 : 16,
        isWide ? 30 : 22,
        isWide ? 32 : 16,
        20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHero(isWide),
              const SizedBox(height: 28),
              const Text(
                'Try asking',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _buildSuggestedQuestions(isWide),
              const SizedBox(height: 28),
              _buildCapabilities(isWide),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME HERO
  // ============================================================

  Widget _buildWelcomeHero(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 34 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFF5F8FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE8FA)),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _welcomeHeroText()),
                const SizedBox(width: 35),
                _welcomeRobot(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeHeroText(),
                const SizedBox(height: 22),
                Center(child: _welcomeRobot()),
              ],
            ),
    );
  }

  Widget _welcomeHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE8FA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 15, color: bisBlue),
              SizedBox(width: 6),
              Text(
                'BIS Knowledge Assistant',
                style: TextStyle(
                  color: bisBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Ask BIS Saathi',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: bisBlue,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Understand Indian Standards, certification '
          'and BIS services with AI assistance.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Ask about an IS number, a product standard, '
          'BIS certification or how to navigate BIS services.',
          style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  // ============================================================
  // ROBOT
  // ============================================================

  Widget _welcomeRobot() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDCE8FA)),
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: bisBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUGGESTED QUESTIONS
  // ============================================================

  Widget _buildSuggestedQuestions(bool isWide) {
    if (isWide) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _suggestedQuestions.map((question) {
          return _SuggestionChip(
            question: question,
            onTap: () {
              _messageController.text = question;
              _sendMessage(question);
            },
          );
        }).toList(),
      );
    }

    return Column(
      children: _suggestedQuestions.map((question) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SuggestionCard(
            question: question,
            onTap: () {
              _messageController.text = question;
              _sendMessage(question);
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // CAPABILITIES
  // ============================================================

  Widget _buildCapabilities(bool isWide) {
    final capabilities = [
      const _Capability(
        icon: Icons.menu_book_outlined,
        title: 'Indian Standards',
        description: 'Ask about IS numbers and product standards.',
      ),
      const _Capability(
        icon: Icons.verified_outlined,
        title: 'Certification',
        description: 'Understand BIS certification information.',
      ),
      const _Capability(
        icon: Icons.fact_check_outlined,
        title: 'Compliance',
        description: 'Get guidance using the BIS knowledge base.',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 2.1 : 4.0,
      ),
      itemCount: capabilities.length,
      itemBuilder: (context, index) {
        final item = capabilities[index];

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: bisBlue, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CONVERSATION
  // ============================================================

  Widget _buildConversation(bool isWide) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 16, 20, isWide ? 32 : 16, 25),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserQuestion(),
              const SizedBox(height: 18),
              if (_isLoading) _buildLoadingCard(),
              if (!_isLoading && _answer.isNotEmpty) _buildAnswerCard(),
              if (!_isLoading && _answer.isEmpty) _buildErrorCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // USER QUESTION
  // ============================================================

  Widget _buildUserQuestion() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 750),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: const BoxDecoration(
          color: bisBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(5),
          ),
        ),
        child: Text(
          _currentQuestion,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: bisBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BIS Saathi is checking its knowledge base...',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Retrieving relevant BIS information '
                  'and preparing an answer in $_languageLabel.',
                  style: const TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANSWER CARD
  // ============================================================

  Widget _buildAnswerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: bisBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIS Saathi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AI-assisted BIS response',
                      style: TextStyle(color: textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              if (_sources.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: Color(0xFF287A3D),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'BIS Sources',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF287A3D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: borderColor),
          const SizedBox(height: 15),
          MarkdownBody(
            data: _answer,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF344054),
              ),
              h1: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF202124),
              ),
              h3: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              strong: const TextStyle(fontWeight: FontWeight.w800),
              listBullet: const TextStyle(fontSize: 14, height: 1.5),
              blockSpacing: 10,
              listIndent: 24,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
          if (_sources.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Divider(color: borderColor),
            const SizedBox(height: 16),
            _buildSources(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/standards',
              arguments: {'query': _currentQuestion},
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: bisBlue,
            side: const BorderSide(color: Color(0xFFB7CEF0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.search, size: 17),
          label: const Text('Find Standard'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/compliance',
              arguments: {'product': _currentQuestion, 'autoGenerate': false},
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: bisBlue,
            side: const BorderSide(color: Color(0xFFB7CEF0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 17),
          label: const Text('Check Compliance'),
        ),
      ],
    );
  }

  // ============================================================
  // SOURCES
  // ============================================================

  Widget _buildSources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_outlined, size: 19, color: bisBlue),
            SizedBox(width: 7),
            Text(
              'Official BIS Sources',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._sources.map((source) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _SourceCard(
              source: source,
              onTap: () => _openSource(source),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3CCCC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'BIS Saathi could not generate an answer. '
              'Please try again.',
              style: TextStyle(color: Color(0xFF7A2020), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE COMPOSER
  // ============================================================

  Widget _buildMessageComposer(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 14, 10, isWide ? 28 : 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              TextField(
                controller: _messageController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration: InputDecoration(
                  hintText: 'Ask anything about BIS...',
                  prefixIcon: const Icon(Icons.search, color: bisBlue),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Material(
                      color: bisBlue,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _isLoading ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(10),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFD),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: bisBlue, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'AI-assisted information. '
                'Verify important compliance decisions '
                'with current official BIS information.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTION CHIP
// ============================================================

class _SuggestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _SuggestionChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: bisBlue),
              const SizedBox(width: 8),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTION CARD - MOBILE
// ============================================================

class _SuggestionCard extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _SuggestionCard({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: bisBlue, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
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
// SOURCE CARD
// ============================================================

class _SourceCard extends StatelessWidget {
  final String source;
  final VoidCallback onTap;

  const _SourceCard({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
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
              const Icon(Icons.language, size: 19, color: bisBlue),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  source,
                  style: const TextStyle(
                    color: bisBlue,
                    fontSize: 11.5,
                    height: 1.35,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new, size: 16, color: bisBlue),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CAPABILITY DATA
// ============================================================

class _Capability {
  final IconData icon;
  final String title;
  final String description;

  const _Capability({
    required this.icon,
    required this.title,
    required this.description,
  });
}
