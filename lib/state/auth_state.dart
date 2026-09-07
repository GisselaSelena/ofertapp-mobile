import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/models.dart';
import '../services/api_client.dart';

/// AuthState representa el estado de sesión: null = no autenticado.
/// Es "estado de aplicación" porque lo necesitan varias pantallas
/// (listado, detalle, favoritos, perfil), no un único widget.
class AuthState {
  final String token;
  final Usuario usuario;

  AuthState({required this.token, required this.usuario});
}

class AuthNotifier extends StateNotifier<AuthState?> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(null);

  Future<void> login(String email, String password) async {
    final data = await _apiClient.post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    final token = data['access_token'] as String;
    final usuario = Usuario.fromJson(data['usuario']);

    _apiClient.setToken(token);
    state = AuthState(token: token, usuario: usuario);
  }

  Future<void> register(String nombre, String email, String password) async {
    final data = await _apiClient.post('/api/auth/register', {
      'nombre': nombre,
      'email': email,
      'password': password,
    });

    final token = data['access_token'] as String;
    final usuario = Usuario.fromJson(data['usuario']);

    _apiClient.setToken(token);
    state = AuthState(token: token, usuario: usuario);
  }

  void logout() {
    _apiClient.setToken(null);
    state = null;
  }

  /// Se llama cuando el backend responde 401 en cualquier petición:
  /// limpia la sesión para que el router redirija a /login.
  void sessionExpired() {
    _apiClient.setToken(null);
    state = null;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState?>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});

/// Conveniencia para saber en un vistazo si hay sesión activa.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});
