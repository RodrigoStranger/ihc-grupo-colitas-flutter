import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../widgets/menu_option_card.dart';
import 'campanas_screen.dart'; // Asegúrate de importar la pantalla de campañas

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
                ],
              ),
            ),
            // Footer con versión
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data!.version : '';
                return _buildFooter(version);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onDonacionesTap() {
    // TODO: Implementar navegación o acción para donaciones
  }

  void _onAdopcionesTap() {
    // TODO: Implementar navegación o acción para adopciones
  }

  void _onCampanasTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CampanasScreen()),
    );
  }

  void _onAnimalesTap() {
    // TODO: Implementar navegación o acción para animales
  }

  Widget _buildFooter(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$loginVersionPrefix ${version.isNotEmpty ? version : '1.0.0'}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
