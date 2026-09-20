import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String androidBaseUrl = 'http://10.0.2.2:8003';
  static const String localBaseUrl = 'http://127.0.0.1:8003';

  static const String _tokenKey = 'bis_saathi_access_token';

  static const Duration timeout = Duration(seconds: 60);

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
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return localBaseUrl;
    }
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token == null || token.trim().isEmpty) {
      throw Exception('Your login session has expired. Please log in again.');
    }

    return token;
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _getToken();

    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  static Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('Unexpected response from BIS Saathi server.');
    } catch (_) {
      throw Exception(
        'The BIS Saathi server returned an invalid response '
        '(${response.statusCode}).',
      );
    }
  }

  static Exception _requestException(String operation, http.Response response) {
    String message = 'Unable to $operation.';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail != null && detail.toString().trim().isNotEmpty) {
          message = detail.toString();
        }
      }
    } catch (_) {
      // Keep default message.
    }

    return Exception('$message (${response.statusCode})');
  }

  // ============================================================
  // ADMIN DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http
        .get(_uri('/api/auth/admin/dashboard'), headers: await _headers())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load the admin dashboard', response);
    }

    return _decodeObject(response);
  }

  // ============================================================
  // ADMIN USERS
  // ============================================================

  static Future<Map<String, dynamic>> getUsers({
    String search = '',
    String role = '',
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (role.trim().isNotEmpty) {
      query['role'] = role.trim();
    }

    if (isActive != null) {
      query['is_active'] = isActive.toString();
    }

    final response = await http
        .get(_uri('/api/auth/admin/users', query), headers: await _headers())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load admin users', response);
    }

    return _decodeObject(response);
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await http
        .get(_uri('/api/auth/admin/users/$userId'), headers: await _headers())
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load user details', response);
    }

    return _decodeObject(response);
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
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('load user activity', response);
    }

    return _decodeObject(response);
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
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

    if (body.isEmpty) {
      throw Exception('No user changes were provided.');
    }

    final response = await http
        .patch(
          _uri('/api/auth/admin/users/$userId'),
          headers: await _headers(json: true),
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _requestException('update the user account', response);
    }

    return _decodeObject(response);
  }
}
