import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://edvhcblegytbfbneujae.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkdmhjYmxlZ3l0YmZibmV1amFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMTM2NjYsImV4cCI6MjA2Mjg4OTY2Nn0.AoZGKDoTzBxl_kzBAV-C_QLCJ9eUzOISKqgEWm2zdmw';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}