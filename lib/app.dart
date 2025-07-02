import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/auth_repository.dart';
import 'viewmodels/donacion_viewmodel.dart';
import 'viewmodels/firma_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/perro_viewmodel.dart';
import 'viewmodels/solicitud_adopcion_viewmodel.dart';
import 'viewmodels/voluntariado_viewmodel.dart';
import 'views/agregar_perro_screen.dart';
import 'views/donaciones_screen.dart';
import 'views/login.dart';
import 'views/main_menu.dart';
import 'views/perros_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = SupabaseAuthRepository();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),

        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(authRepository: authRepository),
        ),

        ChangeNotifierProvider<PerroViewModel>(
          create: (context) => PerroViewModel(),
        ),

        // AÑADE ESTE NUEVO PROVIDER
        ChangeNotifierProvider<DonacionViewModel>(
          create: (context) => DonacionViewModel(),
        ),

        // ViewModel de firmas
        ChangeNotifierProvider<FirmaViewModel>(
          create: (context) => FirmaViewModel(),
        ),

        // ViewModel de solicitudes de adopción
        ChangeNotifierProvider<SolicitudAdopcionViewModel>(
          create: (context) => SolicitudAdopcionViewModel(),
        ),

        // ViewModel de voluntariado
        ChangeNotifierProvider<VoluntariadoViewModel>(
          create: (context) => VoluntariadoViewModel(),
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
          '/donaciones': (context) => const DonacionesScreen(),
        },
      ),
    );
  }
}
