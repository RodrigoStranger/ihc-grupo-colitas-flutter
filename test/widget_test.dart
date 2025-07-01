// Test básico de widget para la aplicación Grupo Colitas Arequipa
//
// Este test verifica que la aplicación se puede construir correctamente
// y que la pantalla de login inicial se muestra apropiadamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ihc_grupo_colitas_flutter/app.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Construir la aplicación y activar un frame
    await tester.pumpWidget(const MyApp());

    // Verificar que la aplicación se construye correctamente
    // Buscamos elementos que deberían estar presentes en la pantalla de login
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Como la aplicación usa Supabase y providers, puede necesitar tiempo para inicializarse
    // Damos tiempo para que los providers se configuren
    await tester.pumpAndSettle();
    
    // Verificar que al menos hay un Scaffold (estructura básica de pantalla)
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
