import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/voluntariado_model.dart';

class VoluntariadoRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Obtener todas las solicitudes de voluntariado con paginación
  Future<List<Voluntariado>> getSolicitudesVoluntariado({
    int page = 0,
    int pageSize = 20,
    bool ascending = false,
  }) async {
    try {
      final response = await _supabase
          .from('SolicitudesVoluntariado')
          .select('''
            IdSolicitanteVoluntariado,
            NombreSolicitanteVoluntariado,
            Numero1SolicitanteVoluntariado,
            Numero2SolicitanteVoluntariado,
            DescripcionSolicitanteVoluntariado,
            EstadoSolicitanteVoluntariado,
            FechaSolicitanteVoluntariado
          ''')
          .order('FechaSolicitanteVoluntariado', ascending: ascending)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (response as List<dynamic>)
          .map((json) => Voluntariado.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes de voluntariado: $e');
    }
  }

  // Método simplificado para obtener todas las solicitudes (compatibilidad con ViewModel actual)
  Future<List<Voluntariado>> getSolicitudes() async {
    return getSolicitudesVoluntariado();
  }

  // Cambiar estado de una solicitud de voluntariado
  Future<bool> cambiarEstadoSolicitud(int idSolicitud, String nuevoEstado) async {
    try {
      await _supabase
          .from('SolicitudesVoluntariado')
          .update({'EstadoSolicitanteVoluntariado': nuevoEstado})
          .eq('IdSolicitanteVoluntariado', idSolicitud);

      return true;
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  // Crear nueva solicitud de voluntariado
  Future<Voluntariado> crearSolicitud(Voluntariado voluntariado) async {
    try {
      final response = await _supabase
          .from('SolicitudesVoluntariado')
          .insert(voluntariado.toJson())
          .select()
          .single();

      return Voluntariado.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear solicitud: $e');
    }
  }

  // Eliminar solicitud de voluntariado
  Future<bool> eliminarSolicitud(int idSolicitud) async {
    try {
      await _supabase
          .from('SolicitudesVoluntariado')
          .delete()
          .eq('IdSolicitanteVoluntariado', idSolicitud);

      return true;
    } catch (e) {
      throw Exception('Error al eliminar solicitud: $e');
    }
  }

  // Buscar solicitudes por nombre
  Future<List<Voluntariado>> buscarSolicitudesPorNombre(String nombre) async {
    try {
      final response = await _supabase
          .from('SolicitudesVoluntariado')
          .select('''
            IdSolicitanteVoluntariado,
            NombreSolicitanteVoluntariado,
            Numero1SolicitanteVoluntariado,
            Numero2SolicitanteVoluntariado,
            DescripcionSolicitanteVoluntariado,
            EstadoSolicitanteVoluntariado,
            FechaSolicitanteVoluntariado
          ''')
          .ilike('NombreSolicitanteVoluntariado', '%$nombre%')
          .order('FechaSolicitanteVoluntariado', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Voluntariado.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar solicitudes: $e');
    }
  }

  // Obtener solicitudes por estado
  Future<List<Voluntariado>> getSolicitudesPorEstado(String estado) async {
    try {
      final response = await _supabase
          .from('SolicitudesVoluntariado')
          .select('''
            IdSolicitanteVoluntariado,
            NombreSolicitanteVoluntariado,
            Numero1SolicitanteVoluntariado,
            Numero2SolicitanteVoluntariado,
            DescripcionSolicitanteVoluntariado,
            EstadoSolicitanteVoluntariado,
            FechaSolicitanteVoluntariado
          ''')
          .eq('EstadoSolicitanteVoluntariado', estado)
          .order('FechaSolicitanteVoluntariado', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Voluntariado.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes por estado: $e');
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<Voluntariado>> watchSolicitudes() {
    return _supabase
        .from('SolicitudesVoluntariado')
        .stream(primaryKey: ['IdSolicitanteVoluntariado'])
        .order('FechaSolicitanteVoluntariado', ascending: false)
        .map((data) => data.map((json) => Voluntariado.fromJson(json)).toList());
  }
}
