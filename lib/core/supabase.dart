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