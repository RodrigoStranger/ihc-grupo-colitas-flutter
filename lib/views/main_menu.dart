import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../widgets/menu_option_card.dart';
import 'solicitudes_adopcion_screen.dart'; // Importar la pantalla de solicitudes de adopción
import 'campanas_screen.dart';
import 'donaciones_screen.dart';
import 'perros_screen.dart';
import 'voluntariado_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        title: Text(
          mainMenuTitle,
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mainMenuWelcome,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: labelTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mainMenuSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  MenuOptionCard(
                    icon: Icons.volunteer_activism,
                    title: menuDonacionesTitle,
                    description: menuDonacionesDesc,
                    onTap: _onDonacionesTap,
                  ),
                  MenuOptionCard(
                    icon: Icons.pets,
                    title: menuAdopcionesTitle,
                    description: menuAdopcionesDesc,
                    onTap: _onAdopcionesTap,
                  ),
                  MenuOptionCard(
                    icon: Icons.campaign,
                    title: menuCampanasTitle,
                    description: menuCampanasDesc,
                    onTap: _onCampanasTap,
                  ),
                  MenuOptionCard(
                    icon: Icons.list_alt,
                    title: menuAnimalesTitle,
                    description: menuAnimalesDesc,
                    onTap: _onAnimalesTap,
                  ),
                  MenuOptionCard(
                    icon: Icons.people,
                    title: menuVoluntariadoTitle,
                    description: menuVoluntariadoDesc,
                    onTap: _onVoluntariadoTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDonacionesTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DonacionesScreen(),
      ), // <--- NAVIGATE TO DonacionesScreen
    );
  }

  void _onAdopcionesTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SolicitudesAdopcionScreen()),
    );
  }

  void _onCampanasTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CampanasScreen()));
  }

  void _onAnimalesTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PerrosScreen()));
  }

  void _onVoluntariadoTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoluntariadoScreen()));
  }
}
