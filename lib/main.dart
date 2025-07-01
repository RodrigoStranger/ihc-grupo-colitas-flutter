import 'package:flutter/material.dart';
import 'app.dart';
import 'core/supabase.dart';

/// Punto de entrada principal de la aplicación Grupo Colitas Arequipa
/// 
/// Esta aplicación Flutter permite la gestión administrativa de un refugio
/// de animales, incluyendo:
/// - Gestión de perros y adopciones
/// - Administración de donaciones
/// - Manejo de campañas y firmas
/// - Panel de administración con autenticación
void main() async {
  // Asegurar que el binding de widgets esté inicializado antes de 
  // ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar la configuración de Supabase para backend y autenticación
  // Esto debe completarse antes de iniciar la aplicación
  await SupabaseConfig.initialize();
  
  // Iniciar la aplicación Flutter
  runApp(const MyApp());
}
