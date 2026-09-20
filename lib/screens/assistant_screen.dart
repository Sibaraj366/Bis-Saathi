import 'package:flutter/material.dart' hide Text;
import '../services/app_language.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

// ============================================================
// BIS COLORS
// ============================================================

const Color bisBlue = Color(0xFF0B5ED7);
const Color backgroundColor = Color(0xFFF7F9FC);
const Color lightBlue = Color(0xFFEAF2FF);
const Color borderColor = Color(0xFFE2E7F0);
const Color textSecondary = Color(0xFF667085);
const Color sidebarColor = Color(0xFFF8FAFD);

// ============================================================
// CHAT TURN
// ============================================================

class _ChatTurn {
  final String question;
  String answer;
  List<String> sources;
  bool isLoading;
  bool hasError;

  _ChatTurn({
    required this.question,
    required this.answer,
    required this.sources,
    required this.isLoading,
    required this.hasError,
  });
}

// ============================================================
// ASSISTANT SCREEN
// ============================================================

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

// ============================================================
// STATE
// ============================================================

class _AssistantScreenState extends State<AssistantScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  // ==========================================================
  // CHAT HISTORY
  // ==========================================================

  final List<_ChatTurn> _chatHistory = [];

  // ==========================================================
  // CONVERSATIONS
  // ==========================================================

  List<ConversationSummary> _conversations = [];

  String? _conversationId;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = false;

  bool _isLoadingConversations = false;

  bool _isLoadingConversation = false;

  // Important:
  // Mobile starts with the history sidebar closed.
  bool _isSidebarOpen = false;

  bool _handledRouteArguments = false;

  String _conversationSearch = '';

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
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSidebarOpen = MediaQuery.sizeOf(context).width >= 850;
      });

      _restoreConversations();
    });
  }

  // ============================================================
  // SEARCH CHANGE
  // ============================================================

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _conversationSearch = _searchController.text.trim().toLowerCase();
    });
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

    // ----------------------------------------------------------
    // OPEN SPECIFIC SAVED CONVERSATION
    // ----------------------------------------------------------

    final conversationId = arguments['conversationId'];

    if (conversationId != null && conversationId.toString().trim().isNotEmpty) {
      final id = conversationId.toString().trim();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _loadConversation(id);
      });

      return;
    }

    // ----------------------------------------------------------
    // OPEN WITH INITIAL MESSAGE
    // ----------------------------------------------------------

    final initialMessage = arguments['initialMessage'];

    if (initialMessage is String && initialMessage.trim().isNotEmpty) {
      final message = initialMessage.trim();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _sendMessage(message);
      });
    }
  }

  // ============================================================
  // RESTORE CONVERSATIONS
  // ============================================================

  Future<void> _restoreConversations() async {
    if (_isLoadingConversations) {
      return;
    }

    setState(() {
      _isLoadingConversations = true;
    });

    try {
      final conversations = await ApiService.getConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
        _isLoadingConversations = false;
      });

      // IMPORTANT:
      //
      // Do NOT automatically open the first old conversation.
      //
      // Assistant opens as a clean chat.
      // Saved conversations open only when the user selects them.
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = [];
        _isLoadingConversations = false;
      });
    }
  }

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  Future<void> _createConversation() async {
    if (_isLoading) {
      return;
    }

    // New Chat is local only.
    //
    // Backend conversation is created only when the
    // user sends the first question.
    _startLocalConversation();
  }

  // ============================================================
  // LOCAL NEW CHAT
  // ============================================================

  void _startLocalConversation() {
    setState(() {
      _conversationId = null;
      _chatHistory.clear();
      _messageController.clear();
      _isLoading = false;
      _isLoadingConversation = false;
    });

    _scrollToBottom();
  }

  // ============================================================
  // LOAD CONVERSATION
  // ============================================================

  Future<void> _loadConversation(String conversationId) async {
    if (_isLoadingConversation) {
      return;
    }

    setState(() {
      _isLoadingConversation = true;
      _conversationId = conversationId;
      _chatHistory.clear();
    });

    try {
      final conversation = await ApiService.getConversation(conversationId);

      if (!mounted) {
        return;
      }

      final turns = <_ChatTurn>[];

      String? pendingQuestion;

      for (final message in conversation.messages) {
        final role = message.role;
        final content = message.content;

        if (content.trim().isEmpty) {
          continue;
        }

        if (role == 'user') {
          pendingQuestion = content;
        } else if (role == 'assistant' && pendingQuestion != null) {
          turns.add(
            _ChatTurn(
              question: pendingQuestion,
              answer: content,
              sources: List<String>.from(message.sources),
              isLoading: false,
              hasError: false,
            ),
          );

          pendingQuestion = null;
        }
      }

      setState(() {
        _chatHistory
          ..clear()
          ..addAll(turns);

        _isLoadingConversation = false;
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingConversation = false;
      });
    }
  }

  // ============================================================
  // SAVE CONVERSATION MESSAGE
  // ============================================================

  Future<void> _saveConversationMessage(
    String role,
    String content, {
    List<String>? sources,
  }) async {
    final conversationId = _conversationId;

    if (conversationId == null || conversationId.trim().isEmpty) {
      return;
    }

    try {
      await ApiService.saveConversationMessage(
        conversationId: conversationId,
        role: role,
        content: content,
        sources: sources ?? <String>[],
      );
    } catch (_) {
      // Persistence failure must not break chat.
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage(String? suggestedMessage) async {
    final message = (suggestedMessage ?? _messageController.text).trim();

    if (message.isEmpty || _isLoading) {
      return;
    }

    _messageController.clear();

    FocusScope.of(context).unfocus();

    // ----------------------------------------------------------
    // CREATE PERSISTENT CONVERSATION ONLY WHEN FIRST MESSAGE
    // IS ACTUALLY SENT
    // ----------------------------------------------------------

    if (_conversationId == null) {
      try {
        final conversation = await ApiService.createConversation(
          title: message.length > 60
              ? '${message.substring(0, 60)}...'
              : message,
        );

        if (mounted) {
          setState(() {
            _conversationId = conversation.id.toString();
          });
        }

        await _restoreConversations();
      } catch (_) {
        // Continue with local chat if persistence fails.
      }
    }

    final turn = _ChatTurn(
      question: message,
      answer: '',
      sources: [],
      isLoading: true,
      hasError: false,
    );

    setState(() {
      _chatHistory.add(turn);
      _isLoading = true;
    });

    _scrollToBottom();

    await _saveConversationMessage('user', message);

    try {
      final result = await ApiService.sendMessage(
        message,
        language: AppLanguage.instance.code,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        turn.answer = result.answer;
        turn.sources = result.sources;
        turn.isLoading = false;
        turn.hasError = false;
        _isLoading = false;
      });

      await _saveConversationMessage(
        'assistant',
        result.answer,
        sources: result.sources,
      );

      await _refreshConversationList();

      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        turn.answer = '';
        turn.sources = [];
        turn.isLoading = false;
        turn.hasError = true;
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  // ============================================================
  // REFRESH CONVERSATION LIST
  // ============================================================

  Future<void> _refreshConversationList() async {
    try {
      final conversations = await ApiService.getConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
      });
    } catch (_) {}
  }

  // ============================================================
  // CHANGE LANGUAGE
  // ============================================================

  Future<void> _changeLanguage(String language) async {
    AppLanguage.instance.setLanguage(language);

    if (_chatHistory.isEmpty || _isLoading) {
      return;
    }

    final latestTurn = _chatHistory.last;

    if (latestTurn.question.trim().isEmpty) {
      return;
    }

    setState(() {
      latestTurn.answer = '';
      latestTurn.sources = [];
      latestTurn.isLoading = true;
      latestTurn.hasError = false;
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final result = await ApiService.sendMessage(
        latestTurn.question,
        language: AppLanguage.instance.code,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        latestTurn.answer = result.answer;
        latestTurn.sources = result.sources;
        latestTurn.isLoading = false;
        latestTurn.hasError = false;
        _isLoading = false;
      });

      await _saveConversationMessage(
        'assistant',
        result.answer,
        sources: result.sources,
      );

      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        latestTurn.answer = '';
        latestTurn.sources = [];
        latestTurn.isLoading = false;
        latestTurn.hasError = true;
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // TOGGLE SIDEBAR
  // ============================================================

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // ============================================================
  // NEW CHAT
  // ============================================================

  Future<void> _newChat() async {
    if (_isLoading) {
      return;
    }

    await _createConversation();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSidebarOpen = MediaQuery.sizeOf(context).width >= 850;
    });
  }

  // ============================================================
  // DELETE CONVERSATION
  // ============================================================

  Future<void> _deleteConversation(ConversationSummary conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete conversation'),
          content: const Text(
            'Are you sure you want to delete this conversation?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.deleteConversation(conversation.id.toString());
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _conversations.removeWhere(
        (item) => item.id.toString() == conversation.id.toString(),
      );

      if (_conversationId == conversation.id.toString()) {
        _conversationId = null;
        _chatHistory.clear();
      }
    });
  }

  // ============================================================
  // FILTERED CONVERSATIONS
  // ============================================================

  List<ConversationSummary> get _filteredConversations {
    if (_conversationSearch.isEmpty) {
      return List<ConversationSummary>.from(_conversations);
    }

    return _conversations.where((conversation) {
      return conversation.title.toLowerCase().contains(_conversationSearch);
    }).toList();
  }

  // ============================================================
  // SCROLL
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    _searchController.removeListener(_handleSearchChanged);

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    AppLanguage.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          if (!isWide) {
            return _buildMobileLayout();
          }

          return _buildDesktopLayout();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout() {
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: _isSidebarOpen ? 285 : 0,
            child: ClipRect(
              child: _isSidebarOpen ? _buildSidebar() : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(true),
                Expanded(
                  child: _chatHistory.isEmpty
                      ? _buildWelcome(true)
                      : _buildConversation(true),
                ),
                _buildMessageComposer(true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(false),
              Expanded(
                child: _chatHistory.isEmpty
                    ? _buildWelcome(false)
                    : _buildConversation(false),
              ),
              _buildMessageComposer(false),
            ],
          ),
          if (_isSidebarOpen)
            Positioned.fill(
              child: Row(
                children: [
                  SizedBox(
                    width: 285,
                    child: Material(elevation: 12, child: _buildSidebar()),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(bool isWide) {
    return Container(
      width: double.infinity,

      // FIX:
      // Mobile header is smaller and does not contain
      // a second subtitle line.
      height: isWide ? 70 : 64,

      padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 6),

      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),

      child: Row(
        children: [
          IconButton(
            tooltip: _isSidebarOpen
                ? 'Hide conversation history'
                : 'Show conversation history',
            onPressed: _toggleSidebar,
            icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
            color: textSecondary,
          ),

          const SizedBox(width: 4),

          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: bisBlue,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWide ? 'BIS Saathi AI Assistant' : 'BIS Saathi AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isWide ? 16 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // The subtitle is intentionally hidden
                // on mobile to prevent header overflow.
                if (isWide) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Indian Standards • Certification • BIS Services',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 10.5),
                  ),
                ],
              ],
            ),
          ),

          _buildLanguageSelector(),

          const SizedBox(width: 6),

          IconButton(
            tooltip: 'New conversation',
            onPressed: _isLoading ? null : _newChat,
            icon: const Icon(Icons.add),
            color: bisBlue,
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
      tooltip: AppLanguage.instance.t('Select language'),
      initialValue: AppLanguage.instance.code,
      onSelected: _changeLanguage,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return const [
          PopupMenuItem<String>(
            value: 'English',
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: bisBlue),
                SizedBox(width: 10),
                Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Hindi',
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: bisBlue),
                SizedBox(width: 10),
                Text('हिंदी', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          PopupMenuItem<String>(
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD5E5FA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: bisBlue),
            const SizedBox(width: 5),
            Text(
              AppLanguage.instance.label,
              style: const TextStyle(
                color: bisBlue,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 15, color: bisBlue),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      color: sidebarColor,
      height: double.infinity,
      child: Column(
        children: [
          _buildSidebarHeader(),
          _buildSidebarSearch(),
          _buildNewChatButton(),
          const SizedBox(height: 12),
          Expanded(child: _buildConversationList()),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR HEADER
  // ============================================================

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: bisBlue, size: 21),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'BIS Saathi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Close history',
            onPressed: _toggleSidebar,
            icon: const Icon(Icons.chevron_left),
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR SEARCH
  // ============================================================

  Widget _buildSidebarSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations',
          prefixIcon: const Icon(Icons.search, size: 19, color: textSecondary),
          suffixIcon: _conversationSearch.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close, size: 18),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: bisBlue),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEW CHAT BUTTON
  // ============================================================

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : _newChat,
          style: OutlinedButton.styleFrom(
            foregroundColor: bisBlue,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFB7CEF0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(Icons.add, size: 19),
          label: const Text(
            'New Chat',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONVERSATION LIST
  // ============================================================

  Widget _buildConversationList() {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator(color: bisBlue));
    }

    final conversations = _filteredConversations;

    if (conversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: bisBlue,
                size: 25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _conversationSearch.isEmpty
                  ? 'No conversations yet'
                  : 'No matching conversations',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 5),
            Text(
              _conversationSearch.isEmpty
                  ? 'Start a new chat with BIS Saathi.'
                  : 'Try another search.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text(
            'RECENT CHATS',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
        ...conversations.map((conversation) {
          final selected = conversation.id.toString() == _conversationId;

          return _buildConversationTile(conversation, selected);
        }),
      ],
    );
  }

  // ============================================================
  // CONVERSATION TILE
  // ============================================================

  Widget _buildConversationTile(
    ConversationSummary conversation,
    bool selected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8F1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Icon(
          selected ? Icons.chat : Icons.chat_bubble_outline,
          size: 18,
          color: selected ? bisBlue : textSecondary,
        ),
        title: Text(
          conversation.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF174EA6) : const Color(0xFF344054),
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Conversation options',
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_horiz, size: 19, color: textSecondary),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteConversation(conversation);
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ];
          },
        ),
        onTap: () async {
          await _loadConversation(conversation.id.toString());

          if (!mounted) {
            return;
          }

          if (MediaQuery.of(context).size.width < 850) {
            setState(() {
              _isSidebarOpen = false;
            });
          }
        },
      ),
    );
  }

  // ============================================================
  // SIDEBAR FOOTER
  // ============================================================

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 18,
              color: bisBlue,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'BIS Saathi AI',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
          const Icon(Icons.security_outlined, size: 17, color: textSecondary),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME
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

  // ============================================================
  // WELCOME TEXT
  // ============================================================

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
    if (_isLoadingConversation) {
      return const Center(child: CircularProgressIndicator(color: bisBlue));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 16, 20, isWide ? 32 : 16, 25),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < _chatHistory.length; index++) ...[
                _buildChatTurn(_chatHistory[index]),
                if (index < _chatHistory.length - 1) const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAT TURN
  // ============================================================

  Widget _buildChatTurn(_ChatTurn turn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserQuestion(turn.question),
        const SizedBox(height: 18),
        if (turn.isLoading) _buildLoadingCard(),
        if (!turn.isLoading && !turn.hasError && turn.answer.isNotEmpty)
          _buildAnswerCard(turn),
        if (!turn.isLoading && turn.hasError) _buildErrorCard(),
      ],
    );
  }

  // ============================================================
  // USER QUESTION
  // ============================================================

  Widget _buildUserQuestion(String question) {
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
          question,
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
                  'and preparing an answer in '
                  '${AppLanguage.instance.label}.',
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
  // ANSWER
  // ============================================================

  Widget _buildAnswerCard(_ChatTurn turn) {
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
              if (turn.sources.isNotEmpty)
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
            data: turn.answer,
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
          _buildActionButtons(turn.question),
          if (turn.sources.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Divider(color: borderColor),
            const SizedBox(height: 16),
            _buildSources(turn.sources),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(String question) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/standards',
              arguments: {'query': question},
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
              arguments: {'product': question, 'autoGenerate': false},
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

  Widget _buildSources(List<String> sources) {
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
        ...sources.map((source) {
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
                  _sendMessage(null);
                },
                decoration: InputDecoration(
                  hintText: AppLanguage.instance.t('Ask anything about BIS...'),
                  prefixIcon: const Icon(Icons.search, color: bisBlue),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Material(
                      color: bisBlue,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _isLoading ? null : () => _sendMessage(null),
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
// SUGGESTION CARD
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
