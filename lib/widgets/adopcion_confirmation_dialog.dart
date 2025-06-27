import 'package:flutter/material.dart';
import '../core/colors.dart';

class AdopcionConfirmationDialog extends StatelessWidget {
  final String nombrePerro;

  const AdopcionConfirmationDialog({
    super.key,
    required this.nombrePerro,
  });

  /// Muestra el diálogo de confirmación de adopción
  static Future<bool?> show(BuildContext context, String nombrePerro) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AdopcionConfirmationDialog(nombrePerro: nombrePerro);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.pets,
            color: accentBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Marcar como Adoptado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás seguro de que quieres marcar a $nombrePerro como adoptado?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 152, 0, 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromRGBO(255, 152, 0, 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta acción cambiará el estado del perro y no se puede deshacer fácilmente.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
