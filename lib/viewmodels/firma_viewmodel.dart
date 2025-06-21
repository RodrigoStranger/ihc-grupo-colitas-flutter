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
  
  // Método auxiliar para notificar a los listeners solo si el ViewModel sigue activo
  void _safeNotifyListeners() {
    if (isActive) {
      notifyListeners();
    }
  }
  
  // Cargar la primera página de firmas
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
}
