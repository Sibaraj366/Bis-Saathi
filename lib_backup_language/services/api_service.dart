import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatResponse {
  final String answer;
  final List<String> sources;

  ChatResponse({required this.answer, required this.sources});
}

class ComplianceResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? standard;
  final String? summary;
  final List<String> checklist;
  final List<String> sources;

  ComplianceResponse({
    required this.success,
    required this.message,
    required this.standard,
    required this.summary,
    required this.checklist,
    required this.sources,
  });
}

class DocumentUploadResponse {
  final bool success;
  final String message;
  final String? documentId;
  final String? filename;
  final int pages;

  DocumentUploadResponse({
    required this.success,
    required this.message,
    required this.documentId,
    required this.filename,
    required this.pages,
  });
}

class DocumentQuestionResponse {
  final bool success;
  final String message;
  final String answer;
  final String? filename;

  DocumentQuestionResponse({
    required this.success,
    required this.message,
    required this.answer,
    required this.filename,
  });
}

class ApiService {
  // Android emulator needs 10.0.2.2 to reach the computer.
  // Web and iOS simulator can use localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8002';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8002';
    }

    return 'http://127.0.0.1:8002';
  }

  // ------------------------------------------------------------
  // Health Check
  // ------------------------------------------------------------

  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // AI Assistant
  // ------------------------------------------------------------
  //
  // Supported languages:
  // English
  // Hindi
  // Marathi
  //
  static Future<ChatResponse> sendMessage(
    String message, {
    String language = 'English',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'language': language}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return ChatResponse(
          answer: data['answer'] ?? 'No answer received.',
          sources: List<String>.from(data['sources'] ?? []),
        );
      }

      return ChatResponse(
        answer: 'Server error: ${response.statusCode}',
        sources: [],
      );
    } catch (e) {
      return ChatResponse(
        answer: 'Could not connect to BIS Saathi server.',
        sources: [],
      );
    }
  }

  // ------------------------------------------------------------
  // Compliance
  // ------------------------------------------------------------
  //
  // The selected language is also sent to the backend so that
  // the AI-generated compliance explanation uses that language.
  //
  static Future<ComplianceResponse> getCompliance(
    String product, {
    String language = 'English',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/compliance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'product': product, 'language': language}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return ComplianceResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'No message received.',
          standard: data['standard'] != null
              ? Map<String, dynamic>.from(data['standard'])
              : null,
          summary: data['summary']?.toString(),
          checklist: List<String>.from(data['checklist'] ?? []),
          sources: List<String>.from(data['sources'] ?? []),
        );
      }

      return ComplianceResponse(
        success: false,
        message: 'Server error: ${response.statusCode}',
        standard: null,
        summary: null,
        checklist: [],
        sources: [],
      );
    } catch (e) {
      return ComplianceResponse(
        success: false,
        message: 'Could not connect to BIS Saathi server.',
        standard: null,
        summary: null,
        checklist: [],
        sources: [],
      );
    }
  }

  // ------------------------------------------------------------
  // Cross-platform PDF upload
  // ------------------------------------------------------------
  //
  // Uses PDF bytes instead of a local file path.
  // This works for Android, iOS and Web.
  //
  static Future<DocumentUploadResponse> uploadDocument(
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/document/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return DocumentUploadResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'No message received.',
          documentId: data['documentId']?.toString(),
          filename: data['filename']?.toString(),
          pages: data['pages'] ?? 0,
        );
      }

      return DocumentUploadResponse(
        success: false,
        message: 'Server error: ${response.statusCode}',
        documentId: null,
        filename: null,
        pages: 0,
      );
    } catch (e) {
      return DocumentUploadResponse(
        success: false,
        message: 'Could not connect to BIS Saathi server.',
        documentId: null,
        filename: null,
        pages: 0,
      );
    }
  }

  // ------------------------------------------------------------
  // Document Q&A
  // ------------------------------------------------------------
  //
  // The selected language is sent to the backend so Gemini
  // answers questions about the uploaded document in that
  // language.
  //
  static Future<DocumentQuestionResponse> askDocument(
    String documentId,
    String question, {
    String language = 'English',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/document/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': documentId,
          'question': question,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return DocumentQuestionResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'No message received.',
          answer: data['answer']?.toString() ?? '',
          filename: data['filename']?.toString(),
        );
      }

      return DocumentQuestionResponse(
        success: false,
        message: 'Server error: ${response.statusCode}',
        answer: '',
        filename: null,
      );
    } catch (e) {
      return DocumentQuestionResponse(
        success: false,
        message: 'Could not connect to BIS Saathi server.',
        answer: '',
        filename: null,
      );
    }
  }
}
