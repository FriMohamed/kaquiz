import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage_service.dart';

class ApiClient {
  final String baseUrl =
      "https://kaquiz-api.moham3d-fri.workers.dev/api";
  final TokenStorageService tokenStorage = TokenStorageService();

  ApiClient();

  Future<T> get<T>(
    String path, {
    required T Function(dynamic data) parser,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );

    return _handleResponse(response, parser);
  }

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic data) parser,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response, parser);
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await tokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(dynamic data) parser,
  ) {
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic>
          ? data['error']?.toString() ?? 'Request failed'
          : 'Request failed';

      throw ApiException(
        statusCode: response.statusCode,
        message: message,
      );
    }

    return parser(data);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}