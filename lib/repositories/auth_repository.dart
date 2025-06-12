import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/supabase.dart';

/// Excepción personalizada para errores de autenticación
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}

/// Repositorio que maneja todas las operaciones de autenticación
abstract class AuthRepository {
  Future<UserModel> signIn({required String email, required String password});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

/// Implementación del repositorio de autenticación usando Supabase
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Error desconocido al iniciar sesión');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AuthException(_getErrorMessage(e.message));
    } catch (e) {
      throw const AuthException('Error de conexión. Verifica tu internet.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw const AuthException('Error al cerrar sesión');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? UserModel.fromSupabaseUser(user) : null;
    });
  }

  /// Convierte los errores de Supabase en mensajes amigables
  String _getErrorMessage(String message) {
    switch (message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Correo electrónico o contraseña incorrectos';
      case 'email not confirmed':
        return 'Por favor, confirma tu correo electrónico';
      case 'too many requests':
        return 'Demasiados intentos. Intenta de nuevo más tarde';
      case 'user not found':
        return 'No existe una cuenta con este correo electrónico';
      case 'invalid email':
        return 'El formato del correo electrónico no es válido';
      case 'password is too weak':
        return 'La contraseña es muy débil';
      case 'email already registered':
        return 'Ya existe una cuenta con este correo electrónico';
      default:
        return message.isNotEmpty 
            ? message 
            : 'Error al iniciar sesión. Intenta de nuevo';
    }
  }
}
