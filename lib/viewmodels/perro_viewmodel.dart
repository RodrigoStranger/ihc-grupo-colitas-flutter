import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/perro_model.dart';
import '../repositories/perro_repository.dart';

class PerroViewModel extends ChangeNotifier {
  final PerroRepository _perroRepository = PerroRepository();

  List<PerroModel> _perros = [];
  bool _isLoading = false;
  String? _error;

  List<PerroModel> get perros => _perros;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;

  // Mapa para rastrear las operaciones de carga de imágenes en curso
  final Map<int, Future<void>> _imageLoadingOperations = {};
  
  // Flag para evitar múltiples notificaciones durante actualizaciones batch
  bool _isBatchUpdating = false;
  
  // Flag para indicar si se necesita una notificación pendiente
  bool _needsNotification = false;
  
  // Flag para verificar si el ViewModel ha sido destruido
  bool _disposed = false;

  /// Notifica cambios de forma segura, evitando setState durante build
  void _safeNotifyListeners() {
    if (_disposed) return; // No hacer nada si está destruido
    
    if (_isBatchUpdating) {
      _needsNotification = true;
      return;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && (_needsNotification || !_isBatchUpdating)) {
        _needsNotification = false;
        notifyListeners();
      }
    });
  }

  /// Obtiene todos los perros
  Future<void> getAllPerros() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notificación inmediata para mostrar el loading

    try {
      _perros = await _perroRepository.getAllPerros();
      notifyListeners(); // Notificación inmediata cuando se obtienen los datos
      
      // Programar la carga de imágenes de forma asincrónica después del frame actual
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_disposed) {
          loadAllImages();
        }
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners(); // Notificación inmediata al finalizar
    }
  }

  /// Busca perros por criterios
  Future<void> searchPerros({
    String? nombre,
    String? raza,
    String? sexo,
    String? estado,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notificación inmediata para mostrar el loading

    try {
      _perros = await _perroRepository.searchPerros(
        nombre: nombre,
        raza: raza,
        sexo: sexo,
        estado: estado,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene un perro por ID
  Future<PerroModel?> getPerroById(String id) async {
    try {
      return await _perroRepository.getPerroById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Crea un nuevo perro con imagen
  Future<bool> createPerroWithImage(PerroModel perro, File imagen) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Verificar que la imagen existe antes de subirla
      if (!await imagen.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Primero subir la imagen
      final nombreArchivo = await _perroRepository.uploadImage(
        imagen.path, 
        perro.fotoPerro!
      );
      
      // Crear el perro con el nombre del archivo
      final perroConImagen = perro.copyWith(fotoPerro: nombreArchivo);
      await _perroRepository.createPerro(perroConImagen);
      
      // Recargar la lista
      await getAllPerros();
      return true;
    } on Exception catch (e) {
      _error = 'Error específico: ${e.toString()}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo perro
  Future<bool> createPerro(PerroModel perro) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _perroRepository.createPerro(perro);
      await getAllPerros(); // Recargar la lista
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza un perro existente
  Future<bool> updatePerro(String id, PerroModel perro) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _perroRepository.updatePerro(id, perro);
      await getAllPerros(); // Recargar la lista
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Valida los datos de un perro
  String? validatePerro(PerroModel perro) {
    if (perro.nombrePerro.trim().isEmpty) {
      return 'El nombre del perro es obligatorio';
    }
    if (perro.nombrePerro.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (perro.edadPerro < 0 || perro.edadPerro > 25) {
      return 'La edad debe ser un número válido entre 0 y 25 años';
    }
    if (perro.razaPerro.trim().isEmpty) {
      return 'La raza es obligatoria';
    }
    if (perro.sexoPerro.trim().isEmpty) {
      return 'El sexo es obligatorio';
    }
    if (perro.pelajePerro.trim().isEmpty) {
      return 'El tipo de pelaje es obligatorio';
    }
    if (perro.actividadPerro.trim().isEmpty) {
      return 'El nivel de actividad es obligatorio';
    }
    if (perro.estadoPerro.trim().isEmpty) {
      return 'El estado es obligatorio';
    }
    if (perro.fotoPerro?.trim().isEmpty ?? true) {
      return 'La foto es obligatoria';
    }
    if (perro.descripcionPerro.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    return null;
  }

  /// Carga las imágenes de todos los perros que necesiten carga
  Future<void> loadAllImages() async {
    if (_disposed || _isBatchUpdating) return; // Evitar llamadas múltiples o si está destruido
    
    _isBatchUpdating = true;
    
    final futures = <Future<void>>[];
    
    for (int i = 0; i < _perros.length; i++) {
      final perro = _perros[i];
      
      // Solo cargar si no está cargando y no es una URL completa
      if (!perro.isLoadingImage && 
          perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          !perro.fotoPerro!.startsWith('http')) {
        
        // Agregar la operación a la lista de futures
        futures.add(_loadPerroImageInternal(i));
      }
    }
    
    // Ejecutar todas las cargas en paralelo
    await Future.wait(futures);
    
    _isBatchUpdating = false;
    _safeNotifyListeners();
  }

  /// Método interno para cargar imagen sin notificar cambios
  Future<void> _loadPerroImageInternal(int index) async {
    if (index < 0 || index >= _perros.length) return;

    final perro = _perros[index];

    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (perro.isLoadingImage ||
        (perro.fotoPerro != null && perro.fotoPerro!.startsWith('http'))) {
      return;
    }

    // Si no hay nombre de archivo de imagen, no hay nada que cargar
    if (perro.fotoPerro == null || perro.fotoPerro!.isEmpty) {
      _updatePerro(
        index,
        perro.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'No hay imagen disponible',
        ),
      );
      return;
    }

    // Si ya hay una operación en curso para este perro, no hacer nada
    if (_imageLoadingOperations.containsKey(index)) return;

    final completer = Completer<void>();
    _imageLoadingOperations[index] = completer.future;

    try {
      // Marcar como cargando
      _updatePerro(index, perro.copyWith(
        isLoadingImage: true,
        errorLoadingImage: null,
      ));

      // Obtener la URL firmada
      final imageUrl = await _perroRepository.getSignedImageUrl(perro.fotoPerro!);

      if (!completer.isCompleted) {
        // Actualizar el perro con la URL de la imagen
        _updatePerro(
          index,
          perro.copyWith(
            fotoPerro: imageUrl,
            isLoadingImage: false,
            errorLoadingImage: null,
          ),
        );
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        // Manejar error
        _updatePerro(
          index,
          perro.copyWith(
            isLoadingImage: false,
            errorLoadingImage: 'Error al cargar imagen: $e',
          ),
        );
        completer.complete();
      }
    } finally {
      _imageLoadingOperations.remove(index);
    }
  }

  /// Carga la imagen de un perro específico
  Future<void> loadPerroImage(int index) async {
    await _loadPerroImageInternal(index);
    _safeNotifyListeners();
  }

  /// Actualiza un perro específico en la lista de forma segura
  void _updatePerro(int index, PerroModel updatedPerro) {
    if (index >= 0 && index < _perros.length) {
      _perros[index] = updatedPerro;
      
      // Solo notificar si no estamos en modo batch update
      if (!_isBatchUpdating) {
        _safeNotifyListeners();
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _imageLoadingOperations.clear();
    super.dispose();
  }
}
