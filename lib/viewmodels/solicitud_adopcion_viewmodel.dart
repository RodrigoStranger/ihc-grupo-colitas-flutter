import 'dart:async';
import 'package:flutter/material.dart';
import '../models/solicitud_adopcion_model.dart';
import '../repositories/solicitud_adopcion_repository.dart';

class SolicitudAdopcionViewModel extends ChangeNotifier {
  final SolicitudAdopcionRepository _repository = SolicitudAdopcionRepository();
  
  // Estado de las solicitudes
  final List<SolicitudAdopcionModel> _solicitudes = [];
  List<SolicitudAdopcionModel> get solicitudes => _solicitudes;
  
  // Estado de paginación
  int _currentPage = 0;
  static const int _pageSize = 15;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  
  // Control de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  
  // Control de errores
  String? _error;
  String? get error => _error;
  
  // Mapa para rastrear las operaciones de carga de imágenes en curso
  final Map<int, Future<void>> _imageLoadingOperations = {};
  
  // Flag para evitar múltiples notificaciones durante actualizaciones batch
  bool _isBatchUpdating = false;
  
  // Flag para indicar si se necesita una notificación pendiente
  bool _needsNotification = false;

  // Control de operaciones de aceptar/rechazar
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  
  String? _processingMessage;
  String? get processingMessage => _processingMessage;

  /// Notifica cambios de forma segura, evitando setState durante build
  void _safeNotifyListeners() {
    if (_isDisposed) return; // No hacer nada si está destruido
    
    if (_isBatchUpdating) {
      _needsNotification = true;
      return;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && (_needsNotification || !_isBatchUpdating)) {
        _needsNotification = false;
        notifyListeners();
      }
    });
  }
  
  // Cargar la imagen de una solicitud específica
  Future<void> loadSolicitudImage(int index) async {
    if (index < 0 || index >= _solicitudes.length) return;
    
    final solicitud = _solicitudes[index];
    
    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (solicitud.isLoadingImage || 
        (solicitud.fotoPerro != null && solicitud.fotoPerro!.startsWith('http'))) {
      return;
    }
    
    // Si no hay nombre de archivo de imagen, no hay nada que cargar
    if (solicitud.fotoPerro == null || solicitud.fotoPerro!.isEmpty) {
      _updateSolicitud(
        index,
        solicitud.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'No hay imagen disponible',
        ),
      );
      return;
    }
    
    // Si ya hay una operación en curso para esta solicitud, no hacer nada
    if (_imageLoadingOperations.containsKey(index)) return;
    
    // Mover la declaración del completer fuera del try para que sea accesible en el catch
    final completer = Completer<void>();
    _imageLoadingOperations[index] = completer.future;
    
    try {
      // Marcar como cargando
      _updateSolicitud(index, solicitud.copyWith(
        isLoadingImage: true, 
        errorLoadingImage: null,
      ));
      
      // Obtener la URL firmada
      final imageUrl = await _repository.getSignedImageUrl(solicitud.fotoPerro!);
      
      if (!completer.isCompleted) {
        // Actualizar la solicitud con la URL de la imagen solo si el completer no se completó
        _updateSolicitud(
          index, 
          solicitud.copyWith(
            fotoPerro: imageUrl,
            isLoadingImage: false,
            errorLoadingImage: null,
          ),
        );
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        // En caso de error, actualizar el estado de error
        _updateSolicitud(
          index, 
          solicitud.copyWith(
            isLoadingImage: false,
            errorLoadingImage: 'Error al cargar la imagen',
          ),
        );
        completer.completeError(e);
      }
    } finally {
      _imageLoadingOperations.remove(index);
    }
  }
  
  // Método auxiliar para actualizar una solicitud en la lista
  void _updateSolicitud(int index, SolicitudAdopcionModel updatedSolicitud) {
    if (index >= 0 && index < _solicitudes.length) {
      _solicitudes[index] = updatedSolicitud;
      _safeNotifyListeners();
    }
  }
  
  bool _isDisposed = false;

  @override
  void dispose() {
    // Cancelar todas las operaciones de carga de imágenes pendientes
    for (final operation in _imageLoadingOperations.values) {
      operation.ignore();
    }
    _imageLoadingOperations.clear();
    _repository.dispose();
    _isDisposed = true;
    super.dispose();
  }
  
  // Método auxiliar para verificar si el ViewModel sigue activo
  bool get isActive => !_isDisposed;
  
  // Cargar la primera página de solicitudes (método simple, usar initializeWithOptimizedImageLoading para carga optimizada)
  Future<void> fetchSolicitudes() async {
    if (_isLoading || _isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    _safeNotifyListeners();
    
    try {
      final newSolicitudes = await _repository.getSolicitudesAdopcion(page: 0, pageSize: _pageSize);
      
      // Verificar si el ViewModel sigue activo antes de actualizar el estado
      if (_isDisposed) return;
      
      _solicitudes.clear();
      _solicitudes.addAll(newSolicitudes);
      _hasMore = newSolicitudes.length == _pageSize;
      
      // Cargar imágenes inmediatamente en paralelo
      if (!_isDisposed) {
        loadAllImagesOptimized();
      }
      
      // Precargar la siguiente página en segundo plano
      if (_hasMore) {
        _preloadNextPage();
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al cargar las solicitudes: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
  
  // Cargar más solicitudes (scroll infinito)
  Future<void> loadMoreSolicitudes() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _isDisposed) return;
    
    _isLoadingMore = true;
    _safeNotifyListeners();
    
    try {
      final newPage = _currentPage + 1;
      final newSolicitudes = await _repository.getSolicitudesAdopcion(page: newPage, pageSize: _pageSize);
      
      // Verificar si el ViewModel sigue activo antes de actualizar el estado
      if (_isDisposed) return;
      
      if (newSolicitudes.isNotEmpty) {
        _solicitudes.addAll(newSolicitudes);
        _currentPage = newPage;
        _hasMore = newSolicitudes.length == _pageSize;
        
        // Precargar la siguiente página en segundo plano
        if (_hasMore) {
          _preloadNextPage();
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al cargar más solicitudes: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        _safeNotifyListeners();
      }
    }
  }
  
  // Precargar la siguiente página en segundo plano
  Future<void> _preloadNextPage() async {
    if (_isLoading || _isLoadingMore || _isDisposed) return;
    
    try {
      await _repository.preloadNextPage(_currentPage, pageSize: _pageSize);
      
      // Verificar si el ViewModel sigue activo después de la precarga
      if (_isDisposed) return;
      
      // Notificar a los listeners que la precarga ha terminado
      _safeNotifyListeners();
    } catch (_) {
      // Ignorar errores en precarga
    }
  }
  
  /// Inicialización optimizada para la primera carga de solicitudes
  Future<void> initializeWithOptimizedImageLoading() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      // Obtener solicitudes sin cargar imágenes todavía
      final newSolicitudes = await _repository.getSolicitudesAdopcion(page: 0, pageSize: _pageSize);
      
      if (_isDisposed) return;
      
      _solicitudes.clear();
      _solicitudes.addAll(newSolicitudes);
      _hasMore = newSolicitudes.length == _pageSize;
      notifyListeners(); // Mostrar la lista inmediatamente
      
      // Cargar imágenes prioritarias inmediatamente
      await _loadPriorityImages(newSolicitudes.take(8).toList());
      
      // Cargar el resto de imágenes en segundo plano
      if (newSolicitudes.length > 8) {
        final remainingSolicitudes = newSolicitudes.skip(8).toList();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed) {
            _loadRemainingImages(remainingSolicitudes, 8);
          }
        });
      }
      
      // Precargar la siguiente página en segundo plano
      if (_hasMore) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isDisposed) {
            _preloadNextPage();
          }
        });
      }
      
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al cargar las solicitudes: ${e.toString()}';
        notifyListeners();
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Carga imágenes prioritarias (primera pantalla)
  Future<void> _loadPriorityImages(List<SolicitudAdopcionModel> prioritySolicitudes) async {
    if (_isDisposed) return;
    
    _isBatchUpdating = true;
    final futures = <Future<void>>[];
    
    for (int i = 0; i < prioritySolicitudes.length; i++) {
      final solicitud = prioritySolicitudes[i];
      final globalIndex = _solicitudes.indexWhere((s) => s.id == solicitud.id);
      
      if (globalIndex != -1 && solicitud.fotoPerro != null && 
          solicitud.fotoPerro!.isNotEmpty && 
          !solicitud.fotoPerro!.startsWith('http')) {
        futures.add(_loadSolicitudImageOptimized(globalIndex));
      }
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    
    _isBatchUpdating = false;
    _safeNotifyListeners();
  }

  /// Carga imágenes restantes en segundo plano
  Future<void> _loadRemainingImages(List<SolicitudAdopcionModel> remainingSolicitudes, int startIndex) async {
    if (_isDisposed) return;
    
    for (int i = 0; i < remainingSolicitudes.length; i++) {
      if (_isDisposed) break;
      
      final solicitud = remainingSolicitudes[i];
      final globalIndex = _solicitudes.indexWhere((s) => s.id == solicitud.id);
      
      if (globalIndex != -1 && solicitud.fotoPerro != null && 
          solicitud.fotoPerro!.isNotEmpty && 
          !solicitud.fotoPerro!.startsWith('http')) {
        await _loadSolicitudImageOptimized(globalIndex);
        
        // Pequeña pausa para no bloquear la UI
        if (i % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }

  /// Método optimizado para cargar imagen con actualización inmediata
  Future<void> _loadSolicitudImageOptimized(int index) async {
    if (index < 0 || index >= _solicitudes.length || _isDisposed) return;

    final solicitud = _solicitudes[index];

    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (solicitud.isLoadingImage ||
        (solicitud.fotoPerro != null && solicitud.fotoPerro!.startsWith('http'))) {
      return;
    }

    // Si no hay nombre de archivo de imagen válido, no hay nada que cargar
    if (solicitud.fotoPerro == null || 
        solicitud.fotoPerro!.isEmpty) {
      return;
    }

    try {
      // Marcar como cargando
      _solicitudes[index] = solicitud.copyWith(
        isLoadingImage: true,
        errorLoadingImage: null,
      );
      
      // Solo notificar si no estamos en modo batch
      if (!_isBatchUpdating) {
        notifyListeners();
      }

      // Obtener la URL firmada (esto es rápido si está cacheado)
      final imageUrl = await _repository.getSignedImageUrl(solicitud.fotoPerro!);

      if (!_isDisposed && index < _solicitudes.length) {
        // Actualizar la solicitud con la URL de la imagen
        _solicitudes[index] = solicitud.copyWith(
          fotoPerro: imageUrl,
          isLoadingImage: false,
          errorLoadingImage: null,
        );
        
        // Solo notificar si no estamos en modo batch
        if (!_isBatchUpdating) {
          notifyListeners(); // Actualización inmediata para mostrar la imagen
        }
      }
    } catch (e) {
      if (!_isDisposed && index < _solicitudes.length) {
        // Manejar error
        _solicitudes[index] = solicitud.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'Error al cargar imagen',
        );
        
        // Solo notificar si no estamos en modo batch
        if (!_isBatchUpdating) {
          notifyListeners();
        }
      }
    }
  }

  /// Carga optimizada de todas las imágenes (más rápida y paralela)
  Future<void> loadAllImagesOptimized() async {
    if (_isDisposed) return;
    
    _isBatchUpdating = true;
    final futures = <Future<void>>[];
    
    for (int i = 0; i < _solicitudes.length; i++) {
      final solicitud = _solicitudes[i];
      
      // Cargar todas las imágenes que necesiten carga
      if (solicitud.fotoPerro != null && 
          solicitud.fotoPerro!.isNotEmpty && 
          !solicitud.fotoPerro!.startsWith('http') &&
          !solicitud.isLoadingImage) {
        
        // Cargar cada imagen en paralelo con actualización inmediata
        futures.add(_loadSolicitudImageOptimized(i));
      }
    }
    
    // Ejecutar todas las cargas en paralelo
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    
    _isBatchUpdating = false;
    _safeNotifyListeners();
  }

  /// Aceptar solicitud de adopción
  Future<bool> aceptarSolicitud(String solicitudId, String perroId) async {
    if (_isProcessing || _isDisposed) return false;
    
    _isProcessing = true;
    _processingMessage = 'Aceptando solicitud...';
    _error = null;
    _safeNotifyListeners();
    
    try {
      final success = await _repository.aceptarSolicitud(solicitudId, perroId);
      
      if (success && !_isDisposed) {
        // Actualizar el estado local de la solicitud
        final index = _solicitudes.indexWhere((s) => s.id == solicitudId);
        if (index != -1) {
          _solicitudes[index] = _solicitudes[index].copyWith(
            estadoSolicitante: 'Aceptado',
          );
        }
        
        _processingMessage = 'Solicitud aceptada exitosamente';
        _safeNotifyListeners();
        
        // Limpiar mensaje después de un tiempo
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            _processingMessage = null;
            _safeNotifyListeners();
          }
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al aceptar solicitud: ${e.toString()}';
        _processingMessage = null;
        _safeNotifyListeners();
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isProcessing = false;
        if (_processingMessage == 'Aceptando solicitud...') {
          _processingMessage = null;
        }
        _safeNotifyListeners();
      }
    }
  }

  /// Rechazar solicitud de adopción
  Future<bool> rechazarSolicitud(String solicitudId) async {
    if (_isProcessing || _isDisposed) return false;
    
    _isProcessing = true;
    _processingMessage = 'Rechazando solicitud...';
    _error = null;
    _safeNotifyListeners();
    
    try {
      final success = await _repository.rechazarSolicitud(solicitudId);
      
      if (success && !_isDisposed) {
        // Actualizar el estado local de la solicitud
        final index = _solicitudes.indexWhere((s) => s.id == solicitudId);
        if (index != -1) {
          _solicitudes[index] = _solicitudes[index].copyWith(
            estadoSolicitante: 'Rechazado',
          );
        }
        
        _processingMessage = 'Solicitud rechazada exitosamente';
        _safeNotifyListeners();
        
        // Limpiar mensaje después de un tiempo
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            _processingMessage = null;
            _safeNotifyListeners();
          }
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al rechazar solicitud: ${e.toString()}';
        _processingMessage = null;
        _safeNotifyListeners();
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isProcessing = false;
        if (_processingMessage == 'Rechazando solicitud...') {
          _processingMessage = null;
        }
        _safeNotifyListeners();
      }
    }
  }

  /// Refrescar la lista de solicitudes
  Future<void> refresh() async {
    if (_isDisposed) return;
    
    _currentPage = 0;
    _hasMore = true;
    await initializeWithOptimizedImageLoading();
  }

  /// Limpiar errores
  void clearError() {
    if (_isDisposed) return;
    
    _error = null;
    _safeNotifyListeners();
  }
}
