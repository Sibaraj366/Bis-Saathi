import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class AdminApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return ApiService.localBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return ApiService.androidBaseUrl;

      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return ApiService.localBaseUrl;
    }
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  static Future<Map<String, String>> _headers() async {
    final token = await ApiService.getAccessToken();

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Exception _error(String operation, http.Response response) {
    String message = 'Unable to $operation.';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail != null && detail.toString().trim().isNotEmpty) {
          message = detail.toString();
        }
      }
    } catch (_) {}

    return Exception('$message (${response.statusCode})');
  }

  // ============================================================
  // ADMIN DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http
        .get(_uri('/api/auth/admin/dashboard'), headers: await _headers())
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw _error('load the admin dashboard', response);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid admin dashboard response.');
    }

    return decoded;
  }

  // ============================================================
  // USERS
  // ============================================================

  static Future<Map<String, dynamic>> getUsers({
    String search = '',
    String role = '',
    bool? isActive,
    int limit = 100,
    int offset = 0,
  }) async {
    final parameters = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    if (role.trim().isNotEmpty) {
      parameters['role'] = role.trim();
    }

    if (isActive != null) {
      parameters['is_active'] = isActive ? 'true' : 'false';
    }

    final response = await http
        .get(
          _uri('/api/auth/admin/users', parameters),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw _error('load users', response);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid users response.');
    }

    return decoded;
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final response = await http
        .get(_uri('/api/auth/admin/users/$userId'), headers: await _headers())
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw _error('load user details', response);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid user details response.');
    }

    return decoded;
  }

  // ============================================================
  // USER ACTIVITY
  // ============================================================

  static Future<Map<String, dynamic>> getUserActivity(int userId) async {
    final response = await http
        .get(
          _uri('/api/auth/admin/users/$userId/activity'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw _error('load user activity', response);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid user activity response.');
    }

    return decoded;
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  static Future<Map<String, dynamic>> updateUser(
    int userId, {
    bool? isActive,
    String? role,
  }) async {
    final body = <String, dynamic>{};

    if (isActive != null) {
      body['is_active'] = isActive;
    }

    if (role != null) {
      body['role'] = role;
    }

    final response = await http
        .patch(
          _uri('/api/auth/admin/users/$userId'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw _error('update the user', response);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid user update response.');
    }

    return decoded;
  }
}
