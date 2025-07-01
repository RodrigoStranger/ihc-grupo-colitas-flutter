import 'dart:async';
import 'package:flutter/material.dart';
import '../models/firma_model.dart';
import '../repositories/firma_repository.dart';

class FirmaViewModel extends ChangeNotifier {
  final FirmaRepository _repository = FirmaRepository();
  
  // Estado de las firmas
  final List<FirmaModel> _firmas = [];
  List<FirmaModel> get firmas => _firmas;
  
  // Estado de paginación
  int _currentPage = 0;
  static const int _pageSize = 12; // Reducido para cargas más rápidas
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
  
  // Cargar la imagen de una firma específica
  Future<void> loadFirmaImage(int index) async {
    if (index < 0 || index >= _firmas.length) return;
    
    final firma = _firmas[index];
    
    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (firma.isLoadingImage || 
        (firma.imagenFirma != null && firma.imagenFirma!.startsWith('http'))) {
      return;
    }
    
    // Si no hay nombre de archivo de imagen, no hay nada que cargar
    if (firma.imagenFirma == null || firma.imagenFirma!.isEmpty) {
      _updateFirma(
        index,
        firma.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'No hay imagen disponible',
        ),
      );
      return;
    }
    
    // Si ya hay una operación en curso para esta firma, no hacer nada
    if (_imageLoadingOperations.containsKey(index)) return;
    
    // Mover la declaración del completer fuera del try para que sea accesible en el catch
    final completer = Completer<void>();
    _imageLoadingOperations[index] = completer.future;
    
    try {
      // Marcar como cargando
      _updateFirma(index, firma.copyWith(
        isLoadingImage: true, 
        errorLoadingImage: null,
      ));
      
      // Obtener la URL firmada
      final imageUrl = await _repository.getSignedImageUrl(firma.imagenFirma!);
      
      if (!completer.isCompleted) {
        // Actualizar la firma con la URL de la imagen solo si el completer no se completó
        _updateFirma(
          index, 
          firma.copyWith(
            imagenFirma: imageUrl,
            isLoadingImage: false,
            errorLoadingImage: null,
          ),
        );
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        // En caso de error, actualizar el estado de error
        _updateFirma(
          index, 
          firma.copyWith(
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
  
  // Método auxiliar para actualizar una firma en la lista
  void _updateFirma(int index, FirmaModel updatedFirma) {
    if (index >= 0 && index < _firmas.length) {
      _firmas[index] = updatedFirma;
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
  
  // Cargar la primera página de firmas (método simple, usar initializeWithOptimizedImageLoading para carga optimizada)
  Future<void> fetchFirmas() async {
    if (_isLoading || _isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    _safeNotifyListeners();
    
    try {
      final newFirmas = await _repository.getFirmas(page: 0, pageSize: _pageSize);
      
      // Verificar si el ViewModel sigue activo antes de actualizar el estado
      if (_isDisposed) return;
      
      _firmas.clear();
      _firmas.addAll(newFirmas);
      _hasMore = newFirmas.length == _pageSize;
      
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
        _error = 'Error al cargar las firmas: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
  
  // Cargar más firmas (scroll infinito)
  Future<void> loadMoreFirmas() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _isDisposed) return;
    
    _isLoadingMore = true;
    _safeNotifyListeners();
    
    try {
      final newPage = _currentPage + 1;
      final newFirmas = await _repository.getFirmas(page: newPage, pageSize: _pageSize);
      
      // Verificar si el ViewModel sigue activo antes de actualizar el estado
      if (_isDisposed) return;
      
      if (newFirmas.isNotEmpty) {
        _firmas.addAll(newFirmas);
        _currentPage = newPage;
        _hasMore = newFirmas.length == _pageSize;
        
        // Precargar la siguiente página en segundo plano
        if (_hasMore) {
          _preloadNextPage();
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al cargar más firmas: ${e.toString()}';
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
  
  /// Inicialización optimizada para la primera carga de firmas
  Future<void> initializeWithOptimizedImageLoading() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      // Obtener firmas sin cargar imágenes todavía
      final newFirmas = await _repository.getFirmas(page: 0, pageSize: _pageSize);
      
      if (_isDisposed) return;
      
      _firmas.clear();
      _firmas.addAll(newFirmas);
      _hasMore = newFirmas.length == _pageSize;
      notifyListeners(); // Mostrar la lista inmediatamente
      
      // Cargar imágenes prioritarias inmediatamente
      await _loadPriorityImages(newFirmas.take(6).toList());
      
      // Cargar el resto de imágenes en segundo plano con menor delay
      if (newFirmas.length > 6) {
        final remainingFirmas = newFirmas.skip(6).toList();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isDisposed) {
            _loadRemainingImages(remainingFirmas, 6);
          }
        });
      }
      
      // Precargar la siguiente página en segundo plano con menor delay
      if (_hasMore) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            _preloadNextPage();
          }
        });
      }
      
    } catch (e) {
      if (!_isDisposed) {
        _error = 'Error al cargar las firmas: ${e.toString()}';
        notifyListeners();
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Método de refresh para el RefreshIndicator
  Future<void> refresh() async {
    await initializeWithOptimizedImageLoading();
  }

  /// Carga imágenes prioritarias (primera pantalla)
  Future<void> _loadPriorityImages(List<FirmaModel> priorityFirmas) async {
    if (_isDisposed) return;
    
    _isBatchUpdating = true;
    final futures = <Future<void>>[];
    
    for (int i = 0; i < priorityFirmas.length; i++) {
      final firma = priorityFirmas[i];
      final globalIndex = _firmas.indexWhere((f) => f.dniFirma == firma.dniFirma);
      
      if (globalIndex != -1 && firma.imagenFirma != null && 
          firma.imagenFirma!.isNotEmpty && 
          !firma.imagenFirma!.startsWith('http')) {
        futures.add(_loadFirmaImageOptimized(globalIndex));
      }
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    
    _isBatchUpdating = false;
    _safeNotifyListeners();
  }

  /// Carga imágenes restantes en segundo plano
  Future<void> _loadRemainingImages(List<FirmaModel> remainingFirmas, int startIndex) async {
    if (_isDisposed) return;
    
    for (int i = 0; i < remainingFirmas.length; i++) {
      if (_isDisposed) break;
      
      final firma = remainingFirmas[i];
      final globalIndex = _firmas.indexWhere((f) => f.dniFirma == firma.dniFirma);
      
      if (globalIndex != -1 && firma.imagenFirma != null && 
          firma.imagenFirma!.isNotEmpty && 
          !firma.imagenFirma!.startsWith('http')) {
        await _loadFirmaImageOptimized(globalIndex);
        
        // Pausa más pequeña para no bloquear la UI
        if (i % 2 == 0) {
          await Future.delayed(const Duration(milliseconds: 25));
        }
      }
    }
  }

  /// Método optimizado para cargar imagen con actualización inmediata
  Future<void> _loadFirmaImageOptimized(int index) async {
    if (index < 0 || index >= _firmas.length || _isDisposed) return;

    final firma = _firmas[index];

    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (firma.isLoadingImage ||
        (firma.imagenFirma != null && firma.imagenFirma!.startsWith('http'))) {
      return;
    }

    // Si no hay nombre de archivo de imagen válido, no hay nada que cargar
    if (firma.imagenFirma == null || 
        firma.imagenFirma!.isEmpty) {
      return;
    }

    try {
      // Marcar como cargando
      _firmas[index] = firma.copyWith(
        isLoadingImage: true,
        errorLoadingImage: null,
      );
      
      // Solo notificar si no estamos en modo batch
      if (!_isBatchUpdating) {
        notifyListeners();
      }

      // Obtener la URL firmada (esto es rápido si está cacheado)
      final imageUrl = await _repository.getSignedImageUrl(firma.imagenFirma!);

      if (!_isDisposed && index < _firmas.length) {
        // Actualizar la firma con la URL de la imagen
        _firmas[index] = firma.copyWith(
          imagenFirma: imageUrl,
          isLoadingImage: false,
          errorLoadingImage: null,
        );
        
        // Solo notificar si no estamos en modo batch
        if (!_isBatchUpdating) {
          notifyListeners(); // Actualización inmediata para mostrar la imagen
        }
      }
    } catch (e) {
      if (!_isDisposed && index < _firmas.length) {
        // Manejar error
        _firmas[index] = firma.copyWith(
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
    
    for (int i = 0; i < _firmas.length; i++) {
      final firma = _firmas[i];
      
      // Cargar todas las imágenes que necesiten carga
      if (firma.imagenFirma != null && 
          firma.imagenFirma!.isNotEmpty && 
          !firma.imagenFirma!.startsWith('http') &&
          !firma.isLoadingImage) {
        
        // Cargar cada imagen en paralelo con actualización inmediata
        futures.add(_loadFirmaImageOptimized(i));
      }
    }
    
    // Ejecutar todas las cargas en paralelo
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    
    _isBatchUpdating = false;
    _safeNotifyListeners();
  }
}
