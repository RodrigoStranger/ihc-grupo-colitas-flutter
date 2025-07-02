import 'package:flutter/material.dart';
import '../models/voluntariado_model.dart';
import '../repositories/voluntariado_repository.dart';

class VoluntariadoViewModel extends ChangeNotifier {
  final VoluntariadoRepository _repository = VoluntariadoRepository();

  List<Voluntariado> _solicitudes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Getters
  List<Voluntariado> get solicitudes => _solicitudes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  // Método para obtener solicitudes
  Future<void> fetchSolicitudes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _solicitudes = await _repository.getSolicitudes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _solicitudes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para refrescar solicitudes (pull-to-refresh)
  Future<void> refreshSolicitudes() async {
    try {
      _solicitudes = await _repository.getSolicitudes();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Método para cargar más solicitudes (paginación - placeholder)
  Future<void> loadMoreSolicitudes() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Por ahora, simulamos que no hay más datos
      // En el futuro, aquí se implementaría la paginación real
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Método para cambiar estado de una solicitud
  Future<void> cambiarEstadoSolicitud(int idSolicitud, String nuevoEstado) async {
    try {
      final success = await _repository.cambiarEstadoSolicitud(idSolicitud, nuevoEstado);
      
      if (success) {
        // Actualizar la solicitud localmente
        final index = _solicitudes.indexWhere(
          (solicitud) => solicitud.idSolicitanteVoluntariado == idSolicitud,
        );
        
        if (index != -1) {
          _solicitudes[index] = _solicitudes[index].copyWith(
            estadoSolicitanteVoluntariado: nuevoEstado,
          );
          notifyListeners();
        }
      } else {
        throw Exception('No se pudo cambiar el estado de la solicitud');
      }
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  // Método para agregar nueva solicitud (para uso futuro)
  Future<void> agregarSolicitud(Voluntariado voluntariado) async {
    try {
      final nuevaSolicitud = await _repository.crearSolicitud(voluntariado);
      _solicitudes.insert(0, nuevaSolicitud);
      notifyListeners();
    } catch (e) {
      throw Exception('Error al agregar solicitud: $e');
    }
  }

  // Método para eliminar solicitud (para uso futuro)
  Future<void> eliminarSolicitud(int idSolicitud) async {
    try {
      final success = await _repository.eliminarSolicitud(idSolicitud);
      
      if (success) {
        _solicitudes.removeWhere(
          (solicitud) => solicitud.idSolicitanteVoluntariado == idSolicitud,
        );
        notifyListeners();
      } else {
        throw Exception('No se pudo eliminar la solicitud');
      }
    } catch (e) {
      throw Exception('Error al eliminar solicitud: $e');
    }
  }

  // Método para limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Método para reinicializar el estado
  void reset() {
    _solicitudes = [];
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
  }
}
