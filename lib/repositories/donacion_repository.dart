import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/donacion_model.dart';

class DonacionRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Obtener todas las solicitudes de donación con paginación
  Future<List<Donacion>> getSolicitudesDonacion({
    int page = 0,
    int pageSize = 20,
    bool ascending = false,
  }) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .select('''
            IdSolicitanteDonacion,
            NombreSolicitanteDonacion,
            Numero1SolicitanteDonacion,
            Numero2SolicitanteDonacion,
            DescripcionSolicitanteDonacion,
            EstadoSolicitanteDonacion,
            FechaSolicitanteDonacion
          ''')
          .order('FechaSolicitanteDonacion', ascending: ascending)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (response as List)
          .map((item) => Donacion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes: ${e.toString()}');
    }
  }

  // Obtener una solicitud específica por ID
  Future<Donacion> getSolicitudDonacion(int id) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .select()
          .eq('IdSolicitanteDonacion', id)
          .single();

      return Donacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener solicitud: ${e.toString()}');
    }
  }

  // Crear una nueva solicitud de donación
  Future<Donacion> crearSolicitudDonacion(Donacion solicitud) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .insert({
            'NombreSolicitanteDonacion': solicitud.nombreSolicitanteDonacion,
            'Numero1SolicitanteDonacion': solicitud.numero1SolicitanteDonacion,
            'Numero2SolicitanteDonacion': solicitud.numero2SolicitanteDonacion,
            'DescripcionSolicitanteDonacion':
                solicitud.descripcionSolicitanteDonacion,
            'EstadoSolicitanteDonacion': solicitud.estadoSolicitanteDonacion,
            // Fecha se asigna automáticamente por la base de datos
          })
          .select()
          .single();

      return Donacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear solicitud: ${e.toString()}');
    }
  }

  // Actualizar una solicitud de donación existente
  Future<Donacion> actualizarSolicitudDonacion(Donacion solicitud) async {
    try {
      if (solicitud.idSolicitanteDonacion == null) {
        throw ArgumentError(
          'El ID de la solicitud no puede ser nulo para actualizar',
        );
      }

      final response = await _supabase
          .from('SolicitudesDonacion')
          .update({
            'NombreSolicitanteDonacion': solicitud.nombreSolicitanteDonacion,
            'Numero1SolicitanteDonacion': solicitud.numero1SolicitanteDonacion,
            'Numero2SolicitanteDonacion': solicitud.numero2SolicitanteDonacion,
            'DescripcionSolicitanteDonacion':
                solicitud.descripcionSolicitanteDonacion,
            'EstadoSolicitanteDonacion': solicitud.estadoSolicitanteDonacion,
          })
          .eq('IdSolicitanteDonacion', solicitud.idSolicitanteDonacion!)
          .select()
          .single();

      return Donacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar solicitud: ${e.toString()}');
    }
  }

  // Cambiar el estado de una solicitud
  Future<Donacion> cambiarEstadoSolicitud(int id, String nuevoEstado) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .update({'EstadoSolicitanteDonacion': nuevoEstado})
          .eq('IdSolicitanteDonacion', id)
          .select()
          .single();

      return Donacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al cambiar estado: ${e.toString()}');
    }
  }

  // Eliminar una solicitud de donación
  Future<void> eliminarSolicitudDonacion(int id) async {
    try {
      await _supabase
          .from('SolicitudesDonacion')
          .delete()
          .eq('IdSolicitanteDonacion', id);
    } catch (e) {
      throw Exception('Error al eliminar solicitud: ${e.toString()}');
    }
  }

  // Buscar solicitudes por nombre o descripción
  Future<List<Donacion>> buscarSolicitudes(String query) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .select()
          .or(
            'NombreSolicitanteDonacion.ilike.%$query%,DescripcionSolicitanteDonacion.ilike.%$query%',
          )
          .order('FechaSolicitanteDonacion', ascending: false);

      return (response as List)
          .map((item) => Donacion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar solicitudes: ${e.toString()}');
    }
  }

  // Filtrar solicitudes por estado
  Future<List<Donacion>> filtrarSolicitudesPorEstado(String estado) async {
    try {
      final response = await _supabase
          .from('SolicitudesDonacion')
          .select()
          .eq('EstadoSolicitanteDonacion', estado)
          .order('FechaSolicitanteDonacion', ascending: false);

      return (response as List)
          .map((item) => Donacion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al filtrar solicitudes: ${e.toString()}');
    }
  }
}
