import 'package:flutter/foundation.dart';

import '../models/donacion_model.dart';
import '../repositories/donacion_repository.dart';

class DonacionViewModel extends ChangeNotifier {
  final DonacionRepository _repository = DonacionRepository();

  List<Donacion> _solicitudes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _filtroEstado;

  List<Donacion> get solicitudes => _solicitudes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get filtroEstado => _filtroEstado;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchSolicitudes({bool resetFiltro = false}) async {
    if (resetFiltro) {
      _filtroEstado = null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getSolicitudesDonacion(page: 0);
      _solicitudes = result;
      _currentPage = 0;
      _hasMore = result.isNotEmpty;
    } catch (e) {
      _error = 'Error al cargar solicitudes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSolicitudes() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getSolicitudesDonacion(
        page: _currentPage + 1,
        ascending: false,
      );

      if (result.isNotEmpty) {
        _solicitudes.addAll(result);
        _currentPage++;
        _hasMore = result.length >= 20; // Asume 20 items por página
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = 'Error al cargar más solicitudes: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> crearSolicitud(Donacion solicitud) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nuevaSolicitud = await _repository.crearSolicitudDonacion(
        solicitud,
      );
      _solicitudes.insert(0, nuevaSolicitud); // Agregar al inicio de la lista
    } catch (e) {
      _error = 'Error al crear solicitud: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarSolicitud(Donacion solicitud) async {
    _isLoading = true;
    notifyListeners();

    try {
      final solicitudActualizada = await _repository
          .actualizarSolicitudDonacion(solicitud);
      final index = _solicitudes.indexWhere(
        (s) => s.idSolicitanteDonacion == solicitud.idSolicitanteDonacion,
      );
      if (index != -1) {
        _solicitudes[index] = solicitudActualizada;
      }
    } catch (e) {
      _error = 'Error al actualizar solicitud: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cambiarEstadoSolicitud(int id, String nuevoEstado) async {
    _isLoading = true;
    notifyListeners();

    try {
      final solicitudActualizada = await _repository.cambiarEstadoSolicitud(
        id,
        nuevoEstado,
      );
      final index = _solicitudes.indexWhere(
        (s) => s.idSolicitanteDonacion == id,
      );
      if (index != -1) {
        _solicitudes[index] = solicitudActualizada;
      }
    } catch (e) {
      _error = 'Error al cambiar estado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPorEstado(String? estado) async {
    _filtroEstado = estado;
    _isLoading = true;
    notifyListeners();

    try {
      final result = estado == null
          ? await _repository.getSolicitudesDonacion(page: 0)
          : await _repository.filtrarSolicitudesPorEstado(estado);

      _solicitudes = result;
      _currentPage = 0;
      _hasMore = result.isNotEmpty;
    } catch (e) {
      _error = 'Error al filtrar solicitudes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarSolicitudes(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.buscarSolicitudes(query);
      _solicitudes = result;
      _currentPage = 0;
      _hasMore = false; // Desactivar carga infinita en búsquedas
    } catch (e) {
      _error = 'Error al buscar solicitudes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSolicitudes() async {
    if (_filtroEstado != null) {
      await filtrarPorEstado(_filtroEstado);
    } else {
      await fetchSolicitudes();
    }
  }
}
