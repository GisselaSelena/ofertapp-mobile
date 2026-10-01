import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiClient {
  final http.Client _client;
  final Duration _timeout;
  String? _token;

  /// [client] permite inyectar un http.Client falso en tests (sin red).
  /// [timeout] es el tiempo máximo de espera por request; por defecto 10s.
  ApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
    : _client = client ?? http.Client();

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> get(String path) async {
    final response = await _conTimeout(
      _client.get(Uri.parse('${Config.apiBaseUrl}$path'), headers: _headers),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _conTimeout(
      _client.post(
        Uri.parse('${Config.apiBaseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _conTimeout(
      _client.put(
        Uri.parse('${Config.apiBaseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _conTimeout(
      _client.delete(Uri.parse('${Config.apiBaseUrl}$path'), headers: _headers),
    );
    return _handleResponse(response);
  }

  Future<http.Response> _conTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión.');
    }
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

    if (status == 409) {
      final detail = _extractDetail(response.body);
      throw ApiException(detail ?? 'Conflicto al procesar la solicitud');
    }

    throw ApiException('Error inesperado (código $status)');
  }

  String? _extractDetail(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
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

/// Traduce cualquier error capturado de una llamada a la API a un mensaje
/// que se le puede mostrar directamente al usuario. Cubre las excepciones
/// tipadas que lanza ApiClient; cualquier otra cosa (típicamente una
/// SocketException por falta de conexión) cae al mensaje de red.
String mensajeDeError(Object error) {
  if (error is AuthException) {
    return 'Tu sesión expiró. Inicia sesión de nuevo.';
  }
  if (error is ForbiddenException) return error.message;
  if (error is ValidationException) return 'Revisa los datos ingresados.';
  if (error is ApiException) return error.message;
  return 'Sin conexión a internet. Intenta de nuevo.';
}
