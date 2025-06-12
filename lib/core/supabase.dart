import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase que maneja la configuración de Supabase
/// y proporciona el cliente de Supabase para la aplicación.
class SupabaseConfig {
  static const String supabaseUrl = 'https://edvhcblegytbfbneujae.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkdmhjYmxlZ3l0YmZibmV1amFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMTM2NjYsImV4cCI6MjA2Mjg4OTY2Nn0.AoZGKDoTzBxl_kzBAV-C_QLCJ9eUzOISKqgEWm2zdmw';

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

  AuthResult({
    required this.success,
    this.error,
    this.user,
  });

  AuthResult.success(this.user) : success = true, error = null;
  AuthResult.failure(this.error) : success = false, user = null;
}

/// Servicio de autenticación con manejo detallado de errores
class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;  /// Inicia sesión con email y contraseña
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
        return AuthResult.success(response.user);      } else {
        return AuthResult.failure('Error desconocido al iniciar sesión');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } on Exception catch (e) {
      // Verificar si es un error de autenticación basado en el mensaje
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid_grant') ||
          errorMessage.contains('unauthorized')) {
        return AuthResult.failure('Correo electrónico o contraseña incorrectos');
      }
      
      if (errorMessage.contains('email not confirmed')) {
        return AuthResult.failure('Por favor, confirma tu correo electrónico');
      }
      
      if (errorMessage.contains('too many requests')) {
        return AuthResult.failure('Demasiados intentos. Intenta de nuevo más tarde');
      }
      
      // Verificar si es un error de red específico
      if (errorMessage.contains('socketexception') || 
          errorMessage.contains('timeoutexception') ||
          errorMessage.contains('httpexception') ||
          errorMessage.contains('network')) {
        return AuthResult.failure('Error de conexión. Verifica tu internet.');
      }
        // Si no es un error de red, podría ser un error de autenticación
      return AuthResult.failure('Error al procesar la solicitud. Verifica tus credenciales.');
    } catch (e) {
      return AuthResult.failure('Error inesperado. Intenta de nuevo.');
    }
  }

  /// Cierra la sesión actual
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtiene el usuario actual
  static User? get currentUser => _supabase.auth.currentUser;  /// Verifica si hay un usuario autenticado
  static bool get isAuthenticated => currentUser != null;
  /// Convierte los errores de Supabase en mensajes amigables
  static String _getErrorMessage(AuthException exception) {
    // Normalizar el mensaje para comparación
    final message = exception.message.toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid credentials') ||
        message.contains('wrong password') ||
        message.contains('incorrect password')) {
      return 'Correo electrónico o contraseña incorrectos';
    }
    
    if (message.contains('email not confirmed') || 
        message.contains('not confirmed')) {
      return 'Por favor, confirma tu correo electrónico';
    }
    
    if (message.contains('too many requests') || 
        message.contains('rate limit')) {
      return 'Demasiados intentos. Intenta de nuevo más tarde';
    }
    
    if (message.contains('user not found') || 
        message.contains('no user found')) {
      return 'No existe una cuenta con este correo electrónico';
    }
    
    if (message.contains('invalid email') || 
        message.contains('malformed email')) {
      return 'El formato del correo electrónico no es válido';
    }
    
    if (message.contains('password is too weak') || 
        message.contains('weak password')) {
      return 'La contraseña es muy débil';
    }
    
    if (message.contains('email already registered') || 
        message.contains('already exists')) {
      return 'Ya existe una cuenta con este correo electrónico';
    }
    
    // Si no coincide con ningún patrón conocido, devolver el mensaje original
    return exception.message.isNotEmpty 
        ? 'Error de autenticación: ${exception.message}' 
        : 'Error al iniciar sesión. Intenta de nuevo';
  }
}