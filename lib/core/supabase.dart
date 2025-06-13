import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase que maneja la configuración de Supabase
/// y proporciona el cliente de Supabase para la aplicación.
class SupabaseConfig {
  static const String supabaseUrl = 'https://edvhcblegytbfbneujae.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkdmhjYmxlZ3l0YmZibmV1amFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMTM2NjYsImV4cCI6MjA2Mjg4OTY2Nn0.AoZGKDoTzBxl_kzBAV-C_QLCJ9eUzOISKqgEWm2zdmw';

  // Esta clase se encarga de inicializar Supabase
  // y de proporcionar el cliente de Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl, // URL de Supabase
      anonKey: supabaseAnonKey, // Clave anónima de Supabase
    );
  }

  // Aqui se define el cliente de Supabase
  // que se usará en toda la aplicación.
  static SupabaseClient get client => Supabase.instance.client;
}

/// Resultado de la autenticación
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  AuthResult({required this.success, this.error, this.user});

  AuthResult.success(this.user) : success = true, error = null;
  AuthResult.failure(this.error) : success = false, user = null;
}

/// Servicio de autenticación con manejo detallado de errores
class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Inicia sesión con email y contraseña
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(response.user);
      } else {
        return AuthResult.failure('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      return AuthResult.failure('Usuario o contraseña incorrectos');
    }
  }

  /// Cierra la sesión current
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtiene el usuario current
  static User? get currentUser => _supabase.auth.currentUser;

  /// Verifica si hay un usuario autenticado
  static bool get isAuthenticated => currentUser != null;
}
