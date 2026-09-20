import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// AUTH RESPONSE
// ============================================================

class AuthResponse {
  final bool success;
  final String message;
  final String accessToken;
  final Map<String, dynamic>? user;

  AuthResponse({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];

    Map<String, dynamic>? user;

    if (rawUser is Map) {
      user = Map<String, dynamic>.from(rawUser);
    }

    return AuthResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      accessToken: json['accessToken']?.toString() ?? '',
      user: user,
    );
  }
}

// ============================================================
// CHAT RESPONSE
// ============================================================

class ChatResponse {
  final String answer;
  final List<String> sources;
  final String intent;
  final String retrievalMode;
  final List<Map<String, dynamic>> matchedStandards;

  ChatResponse({
    required this.answer,
    required this.sources,
    required this.intent,
    required this.retrievalMode,
    required this.matchedStandards,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];

    final sources = rawSources is List
        ? rawSources.map((item) => item.toString()).toList()
        : <String>[];

    final rawStandards = json['matchedStandards'];

    final matchedStandards = rawStandards is List
        ? rawStandards
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return ChatResponse(
      answer: json['answer']?.toString() ?? '',
      sources: sources,
      intent: json['intent']?.toString() ?? '',
      retrievalMode: json['retrievalMode']?.toString() ?? '',
      matchedStandards: matchedStandards,
    );
  }
}

// ============================================================
// COMPLIANCE RESPONSE
// ============================================================

class ComplianceResponse {
  final bool success;
  final Map<String, dynamic>? standard;
  final List<String> checklist;
  final String summary;
  final List<String> sources;
  final String message;

  ComplianceResponse({
    required this.success,
    required this.standard,
    required this.checklist,
    required this.summary,
    required this.sources,
    required this.message,
  });

  factory ComplianceResponse.fromJson(Map<String, dynamic> json) {
    final rawStandard = json['standard'];

    Map<String, dynamic>? standard;

    if (rawStandard is Map) {
      standard = Map<String, dynamic>.from(rawStandard);
    }

    final rawChecklist = json['checklist'];

    final checklist = rawChecklist is List
        ? rawChecklist.map((item) => item.toString()).toList()
        : <String>[];

    final rawSources = json['sources'];

    final sources = rawSources is List
        ? rawSources.map((item) => item.toString()).toList()
        : <String>[];

    return ComplianceResponse(
      success: json['success'] == true,
      standard: standard,
      checklist: checklist,
      summary: json['summary']?.toString() ?? '',
      sources: sources,
      message: json['message']?.toString() ?? '',
    );
  }
}

// ============================================================
// DOCUMENT UPLOAD RESPONSE
// ============================================================

class DocumentUploadResponse {
  final bool success;
  final String documentId;
  final String filename;
  final int pages;
  final int textLength;
  final int chunks;
  final String message;

  DocumentUploadResponse({
    required this.success,
    required this.documentId,
    required this.filename,
    required this.pages,
    required this.textLength,
    required this.chunks,
    required this.message,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResponse(
      success: json['success'] == true,
      documentId: json['documentId']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      pages: _toInt(json['pages']),
      textLength: _toInt(json['textLength']),
      chunks: _toInt(json['chunks']),
      message: json['message']?.toString() ?? '',
    );
  }
}

// ============================================================
// DOCUMENT ASK RESPONSE
// ============================================================

class DocumentAskResponse {
  final bool success;
  final String answer;
  final String message;
  final String filename;
  final List<int> pages;
  final int retrievedChunks;

  DocumentAskResponse({
    required this.success,
    required this.answer,
    required this.message,
    required this.filename,
    required this.pages,
    required this.retrievedChunks,
  });

  factory DocumentAskResponse.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];

    final pages = rawPages is List
        ? rawPages.map((item) => _toInt(item)).toList()
        : <int>[];

    return DocumentAskResponse(
      success: json['success'] == true,
      answer: json['answer']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      pages: pages,
      retrievedChunks: _toInt(json['retrievedChunks']),
    );
  }
}

// ============================================================
// CONVERSATION SUMMARY
// ============================================================

class ConversationSummary {
  final String id;
  final String title;
  final String createdAt;
  final String updatedAt;
  final int messageCount;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New Conversation',
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      updatedAt:
          json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '',
      messageCount: _toInt(json['message_count'] ?? json['messageCount']),
    );
  }
}

// ============================================================
// CONVERSATION MESSAGE
// ============================================================

class ConversationMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final List<String> sources;
  final String createdAt;

  ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.sources,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];

    final sources = rawSources is List
        ? rawSources.map((item) => item.toString()).toList()
        : <String>[];

    return ConversationMessage(
      id: json['id']?.toString() ?? '',
      conversationId:
          json['conversation_id']?.toString() ??
          json['conversationId']?.toString() ??
          '',
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      sources: sources,
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
  }
}

// ============================================================
// CONVERSATION DETAILS
// ============================================================

class ConversationDetails {
  final String id;
  final String title;
  final String createdAt;
  final String updatedAt;
  final List<ConversationMessage> messages;

  ConversationDetails({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ConversationDetails.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];

    final messages = <ConversationMessage>[];

    if (rawMessages is List) {
      for (final item in rawMessages.whereType<Map>()) {
        final message = Map<String, dynamic>.from(item);

        // ------------------------------------------------------
        // Already-normalized Flutter message format
        // ------------------------------------------------------

        final hasRoleFormat =
            message['role'] != null && message['content'] != null;

        if (hasRoleFormat) {
          messages.add(ConversationMessage.fromJson(message));

          continue;
        }

        // ------------------------------------------------------
        // Backend format:
        //
        // {
        //   id,
        //   question,
        //   answer,
        //   sources,
        //   createdAt
        // }
        // ------------------------------------------------------

        final question = message['question']?.toString() ?? '';

        final answer = message['answer']?.toString() ?? '';

        final sources = message['sources'] is List
            ? (message['sources'] as List)
                  .map((source) => source.toString())
                  .toList()
            : <String>[];

        final id = message['id']?.toString() ?? '';

        final conversationId =
            message['conversation_id']?.toString() ??
            message['conversationId']?.toString() ??
            json['id']?.toString() ??
            '';

        final createdAt =
            message['created_at']?.toString() ??
            message['createdAt']?.toString() ??
            '';

        // ------------------------------------------------------
        // Convert backend question into user message
        // ------------------------------------------------------

        if (question.trim().isNotEmpty) {
          messages.add(
            ConversationMessage(
              id: '$id-user',
              conversationId: conversationId,
              role: 'user',
              content: question,
              sources: const <String>[],
              createdAt: createdAt,
            ),
          );
        }

        // ------------------------------------------------------
        // Convert backend answer into assistant message
        // ------------------------------------------------------

        if (answer.trim().isNotEmpty) {
          messages.add(
            ConversationMessage(
              id: '$id-assistant',
              conversationId: conversationId,
              role: 'assistant',
              content: answer,
              sources: sources,
              createdAt: createdAt,
            ),
          );
        }
      }
    }

    return ConversationDetails(
      id: json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? 'New Conversation',
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      updatedAt:
          json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '',
      messages: messages,
    );
  }
}

// ============================================================
// API SERVICE
// ============================================================

class ApiService {
  // Keeps the user's question until the assistant answer arrives.
  //
  // The backend stores one database row containing:
  // question + answer + sources.
  //
  // AssistantScreen currently sends the question and answer
  // through two separate calls, so this temporary cache joins
  // them before sending them to the backend.
  static final Map<String, String> _pendingConversationQuestions =
      <String, String>{};

  // ============================================================
  // BACKEND ADDRESSES
  // ============================================================

  // Android Emulator -> Windows host
  static const String androidBaseUrl = 'http://10.0.2.2:8003';

  // Browser / Windows / macOS / Linux
  static const String localBaseUrl = 'http://127.0.0.1:8003';

  // ============================================================
  // AUTH TOKEN
  // ============================================================

  static const String _tokenKey = 'bis_saathi_access_token';

  // ============================================================
  // PLATFORM-AWARE BASE URL
  // ============================================================

  static String get baseUrl {
    if (kIsWeb) {
      return localBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidBaseUrl;

      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return localBaseUrl;

      case TargetPlatform.iOS:
        return localBaseUrl;

      case TargetPlatform.fuchsia:
        return localBaseUrl;
    }
  }

  // ============================================================
  // TIMEOUT
  // ============================================================

  static const Duration timeout = Duration(seconds: 60);

  // ============================================================
  // URI
  // ============================================================

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  // ============================================================
  // JSON DECODER
  // ============================================================

  static Map<String, dynamic> _decodeObject(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected response from BIS Saathi server.');
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  static Exception _requestException(String operation, http.Response response) {
    String message = 'Unable to $operation.';

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail != null && detail.toString().trim().isNotEmpty) {
          message = detail.toString();
        }
      }
    } catch (_) {
      // Keep friendly fallback.
    }

    return Exception('$message (${response.statusCode})');
  }

  // ============================================================
  // TOKEN STORAGE
  // ============================================================

  static Future<void> _saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_tokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();

    return token != null && token.trim().isNotEmpty;
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);

      _pendingConversationQuestions.clear();
    } catch (_) {
      // Logout must never prevent the app
      // from returning to the login screen.
    }
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await getAccessToken();

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String preferredLanguage = 'English',
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'password': password,
            'preferred_language': preferredLanguage,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('create your BIS Saathi account', response);
    }

    final result = AuthResponse.fromJson(_decodeObject(response));

    if (result.success && result.accessToken.isNotEmpty) {
      await _saveToken(result.accessToken);
    }

    return result;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('log in to BIS Saathi', response);
    }

    final result = AuthResponse.fromJson(_decodeObject(response));

    if (result.success && result.accessToken.isNotEmpty) {
      await _saveToken(result.accessToken);
    }

    return result;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http
        .get(_uri('/api/auth/me'), headers: await _authHeaders())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load your profile', response);
    }

    final data = _decodeObject(response);

    final dynamic user = data['user'];

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return data;
  }

  // ============================================================
  // USER ACTIVITY
  // ============================================================

  static Future<Map<String, dynamic>> getActivity() async {
    final response = await http
        .get(_uri('/api/auth/activity'), headers: await _authHeaders())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load your activity', response);
    }

    final data = _decodeObject(response);

    final dynamic activity = data['activity'];

    if (activity is Map) {
      return Map<String, dynamic>.from(activity);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // RECORD USER ACTIVITY
  // ============================================================

  static Future<void> recordActivity(String activityType) async {
    try {
      final response = await http
          .post(
            _uri('/api/auth/activity'),
            headers: await _authHeaders(json: true),
            body: jsonEncode({'activity_type': activityType}),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Activity tracking should never
        // break the main BIS Saathi feature.
        return;
      }
    } catch (_) {
      // Ignore activity tracking failures.
    }
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  static Future<List<ConversationSummary>> getConversations() async {
    final response = await http
        .get(_uri('/api/auth/conversations'), headers: await _authHeaders())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load your conversations', response);
    }

    final data = _decodeObject(response);

    final dynamic rawConversations = data['conversations'];

    if (rawConversations is! List) {
      return <ConversationSummary>[];
    }

    return rawConversations
        .whereType<Map>()
        .map(
          (item) =>
              ConversationSummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  static Future<ConversationSummary> createConversation({
    String title = 'New Conversation',
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/conversations'),
          headers: await _authHeaders(json: true),
          body: jsonEncode({'title': title}),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('create a new conversation', response);
    }

    final data = _decodeObject(response);

    final dynamic conversation = data['conversation'];

    if (conversation is Map) {
      return ConversationSummary.fromJson(
        Map<String, dynamic>.from(conversation),
      );
    }

    return ConversationSummary.fromJson(data);
  }

  // ============================================================
  // GET CONVERSATION DETAILS
  // ============================================================

  static Future<ConversationDetails> getConversation(
    String conversationId,
  ) async {
    final encodedId = Uri.encodeComponent(conversationId);

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/auth/conversations/$encodedId'),
          headers: await _authHeaders(),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load the conversation', response);
    }

    final data = _decodeObject(response);

    final dynamic conversation = data['conversation'];

    if (conversation is Map) {
      final conversationData = Map<String, dynamic>.from(conversation);

      // IMPORTANT:
      //
      // The backend returns:
      //
      // {
      //   "conversation": {...},
      //   "messages": [...]
      // }
      //
      // Therefore messages must be merged into the
      // conversation object before parsing.
      conversationData['messages'] = data['messages'] is List
          ? data['messages']
          : <dynamic>[];

      return ConversationDetails.fromJson(conversationData);
    }

    return ConversationDetails.fromJson(data);
  }

  // ============================================================
  // SAVE CONVERSATION MESSAGE
  // ============================================================

  static Future<ConversationMessage> saveConversationMessage({
    required String conversationId,
    required String role,
    required String content,
    List<String> sources = const [],
  }) async {
    final cleanConversationId = conversationId.trim();

    final cleanRole = role.trim().toLowerCase();

    final cleanContent = content.trim();

    if (cleanConversationId.isEmpty || cleanContent.isEmpty) {
      throw Exception('Conversation message cannot be empty.');
    }

    // ----------------------------------------------------------
    // USER MESSAGE
    // ----------------------------------------------------------
    //
    // AssistantScreen sends the user question first.
    // The backend stores question + answer together,
    // so temporarily keep the question here.
    // ----------------------------------------------------------

    if (cleanRole == 'user') {
      _pendingConversationQuestions[cleanConversationId] = cleanContent;

      return ConversationMessage(
        id: 'pending-user-${DateTime.now().microsecondsSinceEpoch}',
        conversationId: cleanConversationId,
        role: 'user',
        content: cleanContent,
        sources: const <String>[],
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
    }

    // ----------------------------------------------------------
    // ASSISTANT MESSAGE
    // ----------------------------------------------------------

    if (cleanRole != 'assistant' && cleanRole != 'ai' && cleanRole != 'bot') {
      throw Exception('Unsupported conversation message role: $role');
    }

    String? question = _pendingConversationQuestions[cleanConversationId];

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------
    //
    // If there is no pending question, load the existing
    // conversation and use its latest user question.
    // This supports answer regeneration/language changes.
    // ----------------------------------------------------------

    if (question == null || question.trim().isEmpty) {
      try {
        final existing = await getConversation(cleanConversationId);

        for (final message in existing.messages.reversed) {
          if (message.role == 'user' && message.content.trim().isNotEmpty) {
            question = message.content.trim();
            break;
          }
        }
      } catch (_) {
        // Do not break the chat UI if
        // the history cannot be loaded.
      }
    }

    if (question == null || question.trim().isEmpty) {
      throw Exception('The question for this conversation could not be found.');
    }

    final encodedId = Uri.encodeComponent(cleanConversationId);

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/conversations/$encodedId/messages'),
          headers: await _authHeaders(json: true),
          body: jsonEncode({
            // Backend expects question + answer,
            // not role + content.
            'question': question,
            'answer': cleanContent,
            'sources': sources,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('save the conversation message', response);
    }

    _pendingConversationQuestions.remove(cleanConversationId);

    final data = _decodeObject(response);

    final now =
        data['createdAt']?.toString() ??
        DateTime.now().toUtc().toIso8601String();

    return ConversationMessage(
      id:
          data['messageId']?.toString() ??
          'saved-assistant-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: data['conversationId']?.toString() ?? cleanConversationId,
      role: 'assistant',
      content: cleanContent,
      sources: List<String>.from(sources),
      createdAt: now,
    );
  }

  // ============================================================
  // DELETE CONVERSATION
  // ============================================================

  static Future<void> deleteConversation(String conversationId) async {
    final encodedId = Uri.encodeComponent(conversationId);

    final response = await http
        .delete(
          Uri.parse('$baseUrl/api/auth/conversations/$encodedId'),
          headers: await _authHeaders(),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('delete the conversation', response);
    }

    _pendingConversationQuestions.remove(conversationId);
  }

  // ============================================================
  // HEALTH
  // ============================================================

  static Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/api/health')).timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('check the BIS Saathi server', response);
    }

    return _decodeObject(response);
  }

  // ============================================================
  // AI CHAT
  // ============================================================

  static Future<ChatResponse> sendMessage(
    String message, {
    String language = 'English',
  }) async {
    final response = await http
        .post(
          _uri('/api/chat'),
          headers: await _authHeaders(json: true),
          body: jsonEncode({'message': message, 'language': language}),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('get a response from BIS Saathi AI', response);
    }

    final result = ChatResponse.fromJson(_decodeObject(response));

    // Record only successful questions.
    await recordActivity('chat');

    return result;
  }

  // ============================================================
  // STANDARDS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getStandards({
    String query = '',
    String category = '',
    String industry = '',
  }) async {
    final parameters = <String, String>{};

    if (query.trim().isNotEmpty) {
      parameters['query'] = query.trim();
    }

    if (category.trim().isNotEmpty) {
      parameters['category'] = category.trim();
    }

    if (industry.trim().isNotEmpty) {
      parameters['industry'] = industry.trim();
    }

    final response = await http
        .get(_uri('/api/standards', parameters), headers: await _authHeaders())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load BIS standards', response);
    }

    final data = _decodeObject(response);

    final dynamic standards = data['standards'];

    if (standards is! List) {
      throw Exception(
        'BIS standards response did not '
        'contain a valid standards list.',
      );
    }

    return standards
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // STANDARD DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> getStandardDetails(
    String isNumber,
  ) async {
    final encoded = Uri.encodeComponent(isNumber);

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/standards/$encoded'),
          headers: await _authHeaders(),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load the BIS standard details', response);
    }

    final data = _decodeObject(response);

    final dynamic standard = data['standard'];

    if (standard is! Map) {
      throw Exception('BIS standard details response is invalid.');
    }

    // Record a standard view only after
    // successfully loading the standard.
    await recordActivity('standard_view');

    return Map<String, dynamic>.from(standard);
  }

  // ============================================================
  // COMPLIANCE
  // ============================================================

  static Future<ComplianceResponse> getCompliance(
    String product, {
    String language = 'English',
  }) async {
    final response = await http
        .post(
          _uri('/api/compliance'),
          headers: await _authHeaders(json: true),
          body: jsonEncode({'product': product, 'language': language}),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('generate the compliance information', response);
    }

    final result = ComplianceResponse.fromJson(_decodeObject(response));

    if (result.success) {
      await recordActivity('compliance_check');
    }

    return result;
  }

  // ============================================================
  // DOCUMENT UPLOAD
  // ============================================================

  static Future<DocumentUploadResponse> uploadDocument(
    String filename,
    Uint8List bytes,
  ) async {
    final request = http.MultipartRequest('POST', _uri('/api/document/upload'));

    final token = await getAccessToken();

    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResponse = await request.send().timeout(timeout);

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('upload the document', response);
    }

    final result = DocumentUploadResponse.fromJson(_decodeObject(response));

    if (result.success) {
      await recordActivity('document_upload');
    }

    return result;
  }

  // ============================================================
  // DOCUMENT Q&A
  // ============================================================

  static Future<DocumentAskResponse> askDocument(
    String documentId,
    String question, {
    String language = 'English',
  }) async {
    final response = await http
        .post(
          _uri('/api/document/ask'),
          headers: await _authHeaders(json: true),
          body: jsonEncode({
            'document_id': documentId,
            'question': question,
            'language': language,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _requestException('answer your document question', response);
    }

    final result = DocumentAskResponse.fromJson(_decodeObject(response));

    if (result.success) {
      await recordActivity('document_question');
    }

    return result;
  }
}

// ============================================================
// INTEGER HELPER
// ============================================================

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
