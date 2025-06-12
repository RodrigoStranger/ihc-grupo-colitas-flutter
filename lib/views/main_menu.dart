import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/main_menu_viewmodel.dart';
import '../widgets/menu_option_card.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainMenuViewModel>(
      builder: (context, viewModel, child) {        // Escuchar cambios en el estado de autenticación
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!viewModel.isAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        });

        return Scaffold(
          backgroundColor: lightPastelBlue,
          appBar: AppBar(
            title: Text(
              appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: primaryPastelBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, viewModel),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(viewModel),
                  const SizedBox(height: 24),
                  _buildMenuOptions(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(MainMenuViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryPastelBlue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: lightPastelBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryPastelBlue, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/grupo_colitas.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuWelcomeTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.currentUser?.email ?? 'Usuario',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            menuWelcomeSubtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          menuOptionsTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,          children: [
            MenuOptionCard(
              title: menuOptionAdoptionsTitle,
              description: menuAdopcionesDesc,
              icon: Icons.pets,
              onTap: () => _navigateToSection(context, 'adopciones'),
            ),
            MenuOptionCard(
              title: menuOptionEventsTitle,
              description: menuCampanasDesc,
              icon: Icons.event,
              onTap: () => _navigateToSection(context, 'eventos'),
            ),
            MenuOptionCard(
              title: menuOptionVolunteeringTitle,
              description: 'Únete como voluntario en nuestras actividades',
              icon: Icons.volunteer_activism,
              onTap: () => _navigateToSection(context, 'voluntariado'),
            ),
            MenuOptionCard(
              title: menuOptionDonationsTitle,
              description: menuDonacionesDesc,
              icon: Icons.favorite,
              onTap: () => _navigateToSection(context, 'donaciones'),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToSection(BuildContext context, String section) {
    // Por ahora mostramos un mensaje, en el futuro se navegará a la sección correspondiente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a $section...'),
        backgroundColor: primaryPastelBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, MainMenuViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}