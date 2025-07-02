import 'package:flutter/material.dart';
import '../core/colors.dart';

class VoluntariadoScreen extends StatelessWidget {
  const VoluntariadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        title: const Text(
          'Gestión de Voluntariado',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: whiteColor),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism,
                size: 80,
                color: accentBlue,
              ),
              SizedBox(height: 24),
              Text(
                'Gestión de Voluntariado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidad está en desarrollo.\n\nAquí podrás administrar voluntarios y actividades de voluntariado del Grupo Colitas.',
                style: TextStyle(
                  fontSize: 16,
                  color: labelTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
