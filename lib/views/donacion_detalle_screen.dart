import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/donacion_model.dart';

class DonacionDetalleScreen extends StatelessWidget {
  final Donacion solicitud;

  const DonacionDetalleScreen({super.key, required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        backgroundColor: accentBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(
              'ID:',
              solicitud.idSolicitanteDonacion?.toString() ?? 'N/A',
            ),
            _buildDetailItem(
              'Solicitante:',
              solicitud.nombreSolicitanteDonacion,
            ),
            _buildDetailItem(
              'Teléfono principal:',
              solicitud.numero1SolicitanteDonacion,
            ),
            if (solicitud.numero2SolicitanteDonacion != null &&
                solicitud.numero2SolicitanteDonacion!.isNotEmpty)
              _buildDetailItem(
                'Teléfono secundario:',
                solicitud.numero2SolicitanteDonacion!,
              ),
            _buildDetailItem(
              'Descripción:',
              solicitud.descripcionSolicitanteDonacion,
            ),
            _buildDetailItem('Estado:', solicitud.estadoSolicitanteDonacion),
            _buildDetailItem(
              'Fecha:',
              solicitud.fechaSolicitanteDonacion.toString(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactOptions(context),
        backgroundColor: accentBlue,
        child: const Icon(Icons.phone, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18)),
          const Divider(height: 20),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    final options = [
      if (solicitud.numero1SolicitanteDonacion.isNotEmpty)
        _ContactOption(
          number: solicitud.numero1SolicitanteDonacion,
          label: 'Llamar al teléfono principal',
        ),
      if (solicitud.numero2SolicitanteDonacion != null &&
          solicitud.numero2SolicitanteDonacion!.isNotEmpty)
        _ContactOption(
          number: solicitud.numero2SolicitanteDonacion!,
          label: 'Llamar al teléfono secundario',
        ),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Opciones de contacto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...options.map(
            (option) => ListTile(
              leading: const Icon(Icons.phone),
              title: Text(option.label),
              onTap: () => _makePhoneCall(context, option.number),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context, String number) {
    Navigator.pop(context);
    // Implementar lógica de llamada aquí
  }
}

class _ContactOption {
  final String number;
  final String label;

  _ContactOption({required this.number, required this.label});
}
