import 'package:flutter/material.dart';
import 'app.dart';
import 'core/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}
