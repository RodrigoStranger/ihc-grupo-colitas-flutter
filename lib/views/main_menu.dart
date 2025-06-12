import 'package:flutter/material.dart';
import '../widgets/menu_option_card.dart';
import '../core/strings.dart';
import '../core/colors.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        title: const Text(mainMenuTitle),
        backgroundColor: primaryPastelBlue,
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
                    color: darkPastelBlue,
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
                children: const [
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _onDonacionesTap() {
    // TODO: Implementar navegación o acción para donaciones
  }

  static void _onAdopcionesTap() {
    // TODO: Implementar navegación o acción para adopciones
  }

  static void _onCampanasTap() {
    // TODO: Implementar navegación o acción para campañas
  }

  static void _onAnimalesTap() {
    // TODO: Implementar navegación o acción para animales
  }
}
