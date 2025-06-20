import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/firma_model.dart';
import '../core/supabase.dart';

class FirmaRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<FirmaModel>> getFirmas() async {
    final response = await _supabase
        .from('CampañaFirmas')
        .select()
        .order('FechaRegistro', ascending: false); // Corregido el nombre de la columna
    return (response as List)
        .map((item) => FirmaModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
