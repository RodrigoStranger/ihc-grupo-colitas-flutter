import 'package:flutter/material.dart';
import 'core/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isConnected = false;
  String errorMessage = '';
  
  try {
    await SupabaseConfig.initialize();
    // Test the connection by getting the current session
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      isConnected = true;
    } else {
      // If no session, try to get the server's time
      await SupabaseConfig.client.from('').select('now()').maybeSingle();
      isConnected = true;
    }
  } catch (e) {
    errorMessage = e.toString();
  }
  
  runApp(MyApp(isConnected: isConnected, errorMessage: errorMessage));
}

class MyApp extends StatelessWidget {
  final bool isConnected;
  final String errorMessage;
  
  const MyApp({
    super.key, 
    required this.isConnected,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conexión Supabase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Conexión a Supabase'),
        ),
        body: Center(
          child: isConnected
              ? const Text(
                  '✅ Conectado a Supabase exitosamente!',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '❌ Error al conectar con Supabase',
                      style: TextStyle(fontSize: 20, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
