import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// ViewModel para manejar la lógica de autenticación del login
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  AuthState _state = const AuthState.initial();
  AuthState get state => _state;

  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Inicia sesión con email y contraseña
  Future<void> signIn({
    required String email, 
    required String password,
  }) async {
    // Validaciones básicas
    if (email.trim().isEmpty) {
      _updateState(const AuthState.error('Por favor, ingresa tu correo electrónico'));
      return;
    }

    if (password.isEmpty) {
      _updateState(const AuthState.error('Por favor, ingresa tu contraseña'));
      return;
    }

    if (!_isValidEmail(email)) {
      _updateState(const AuthState.error('Por favor, ingresa un correo electrónico válido'));
      return;
    }    // Iniciar proceso de autenticación
    _updateState(const AuthState.loading());

    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      
      _updateState(AuthState.authenticated(user));
    } on AuthException catch (e) {
      _updateState(AuthState.error(e.message));
    } catch (e) {
      _updateState(const AuthState.error('Error inesperado. Intenta de nuevo.'));
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    _updateState(const AuthState.loading());
    
    try {
      await _authRepository.signOut();
      _updateState(const AuthState.unauthenticated());
    } on AuthException catch (e) {
      _updateState(AuthState.error(e.message));
    } catch (e) {
      _updateState(const AuthState.error('Error al cerrar sesión'));
    }
  }

  /// Verifica si hay un usuario autenticado
  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _updateState(AuthState.authenticated(user));
      } else {
        _updateState(const AuthState.unauthenticated());
      }
    } catch (e) {
      _updateState(const AuthState.unauthenticated());
    }
  }

  /// Limpia el estado de error
  void clearError() {
    if (_state.status == AuthStatus.error) {
      _updateState(const AuthState.initial());
    }
  }

  /// Actualiza el estado y notifica a los listeners
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Valida el formato del email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim());
  }
  /// Getters de conveniencia
  bool get isLoading => _state.isLoading;
  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get hasError => _state.status == AuthStatus.error;
  String? get errorMessage => _state.error;
  UserModel? get currentUser => _state.user;
}
