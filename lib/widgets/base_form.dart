import 'package:flutter/material.dart';

abstract class BaseForm extends StatelessWidget {
  final String title; // Título del formulario
  final List<Widget> fields; // Lista de campos del formulario
  final VoidCallback onSubmit; // Callback para manejar el envío del formulario
  final String submitButtonText; // Texto del botón de envío

  const BaseForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.submitButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...fields,
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onSubmit,
              child: Text(submitButtonText),
            ),
          ],
        ),
      ),
    );
  }
}