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
        throw const AuthException('Usuario o contraseña incorrectos');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } catch (e) {
      throw const AuthException('Usuario o contraseña incorrectos');
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
}
