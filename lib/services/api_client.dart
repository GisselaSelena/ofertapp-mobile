import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiClient {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('${Config.apiBaseUrl}$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('${Config.apiBaseUrl}$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (status == 401) {
      throw AuthException('Sesión expirada o no autenticado');
    }

    if (status == 403) {
      throw ForbiddenException('No tienes permiso para esta acción');
    }

    if (status == 422) {
      final data = jsonDecode(response.body);
      throw ValidationException(_extractFieldErrors(data));
    }

    throw ApiException('Error inesperado (código $status)');
  }

  Map<String, String> _extractFieldErrors(dynamic data) {
    final errors = <String, String>{};
    if (data is Map && data['detail'] is List) {
      for (final item in data['detail']) {
        if (item is Map && item['loc'] is List && item['loc'].length > 1) {
          final field = item['loc'].last.toString();
          errors[field] = item['msg']?.toString() ?? 'Campo inválido';
        }
      }
    }
    if (errors.isEmpty) {
      errors['_general'] = 'Verifica los datos ingresados';
    }
    return errors;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}

class ValidationException implements Exception {
  final Map<String, String> fieldErrors;
  ValidationException(this.fieldErrors);
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}