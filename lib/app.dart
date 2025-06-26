import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/login.dart';
import 'views/main_menu.dart';
import 'views/perros_screen.dart';
import 'views/agregar_perro_screen.dart';
import 'repositories/auth_repository.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/perro_viewmodel.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear instancia del repositorio
    final authRepository = SupabaseAuthRepository();

    return MultiProvider(
      providers: [
        // Repositorio de autenticación
        Provider<AuthRepository>.value(value: authRepository),

        // ViewModel de login
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(authRepository: authRepository),
        ),

        // ViewModel de perros
        ChangeNotifierProvider<PerroViewModel>(
          create: (context) => PerroViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Grupo Colitas Arequipa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/login': (context) => const LoginScreen(),
          '/menu': (context) => const MainMenuScreen(),
          '/perros': (context) => const PerrosScreen(),
          '/agregar-perro': (context) => const AgregarPerroScreen(),
        },
      ),
    );
  }
}
