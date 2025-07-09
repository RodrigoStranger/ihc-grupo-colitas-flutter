import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/perro_model.dart';
import '../repositories/perro_repository.dart';

/// ViewModel principal para la gestión de perros en el refugio
/// 
/// Esta clase implementa el patrón MVVM y se encarga de:
/// - Mantener el estado global de la lista de perros
/// - Gestionar operaciones CRUD (Crear, Leer, Actualizar, Eliminar)
/// - Optimizar la carga de imágenes con cache inteligente
/// - Manejar estados de loading, error y datos
/// - Proporcionar métodos reactivos para la UI
/// 
/// Características técnicas:
/// - Cache de URLs firmadas con expiración automática
/// - Carga optimizada de imágenes (lazy loading + precarga)
/// - Operaciones batch para mejor rendimiento
/// - Manejo seguro de estados asíncronos
/// - Prevención de memory leaks con flag de disposed
class PerroViewModel extends ChangeNotifier {
  // Repositorio para operaciones de datos con Supabase
  final PerroRepository _perroRepository = PerroRepository();

  // Estado principal de la aplicación
  List<PerroModel> _perros = [];        // Lista de perros cargados
  bool _isLoading = false;              // Indicador de carga general
  String? _error;                       // Mensaje de error actual

  // Getters públicos para acceso controlado al estado
  List<PerroModel> get perros => _perros;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;   // Alias para compatibilidad

  // === SISTEMA DE GESTIÓN DE IMÁGENES ===
  // Mapa para rastrear las operaciones de carga de imágenes en curso
  // Evita cargas duplicadas de la misma imagen
  final Map<int, Future<void>> _imageLoadingOperations = {};
  
  // Cache de URLs firmadas para evitar regenerarlas constantemente
  // Las URLs de Supabase Storage expiran, por lo que necesitamos renovarlas
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlCacheExpiry = {};
  
  // === SISTEMA DE NOTIFICACIONES OPTIMIZADO ===
  // Flag para evitar múltiples notificaciones durante actualizaciones batch
  // Mejora el rendimiento cuando se actualizan muchos elementos a la vez
  bool _isBatchUpdating = false;
  
  // Flag para indicar si se necesita una notificación pendiente
  bool _needsNotification = false;
  
  // Flag para verificar si el ViewModel ha sido destruido
  // Previene memory leaks y errores al intentar notificar después del dispose
  bool _disposed = false;

  /// Notifica cambios de forma segura, evitando setState durante build
  /// 
  /// Este método previene errores comunes de Flutter cuando se intenta
  /// actualizar el estado durante la construcción de widgets
  void _safeNotifyListeners() {
    // No hacer nada si el ViewModel ha sido destruido
    if (_disposed) return; 
    
    // Si estamos en modo batch, marcar que necesitamos notificar después
    if (_isBatchUpdating) {
      _needsNotification = true;
      return;
    }
    
    // Programar la notificación para después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && (_needsNotification || !_isBatchUpdating)) {
        _needsNotification = false;
        notifyListeners();
      }
    });
  }

  /// Normaliza el nombre de archivo para evitar problemas de compatibilidad
  String _normalizeFileName(String fileName) {
    // Quitar rutas, espacios, tildes y convertir a minúsculas
    String name = fileName.trim();
    if (name.contains('/')) {
      name = name.split('/').last;
    }
    name = name.replaceAll(' ', '_');
    // Opcional: puedes agregar más normalizaciones si tus archivos tienen tildes o caracteres especiales
    return name;
  }

  /// Obtiene URL firmada desde caché o la genera nueva si es necesaria
  Future<String?> _getCachedImageUrl(String fileName) async {
    final normalizedFileName = _normalizeFileName(fileName);
    // Verificar si tenemos una URL válida en caché
    if (_urlCache.containsKey(normalizedFileName)) {
      final expiry = _urlCacheExpiry[normalizedFileName];
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        return _urlCache[normalizedFileName];
      } else {
        // URL expirada, limpiar del caché
        _urlCache.remove(normalizedFileName);
        _urlCacheExpiry.remove(normalizedFileName);
      }
    }

    try {
      // Generar nueva URL firmada
      final newUrl = await _perroRepository.getSignedImageUrl(normalizedFileName);
      _urlCache[normalizedFileName] = newUrl;
      _urlCacheExpiry[normalizedFileName] = DateTime.now().add(const Duration(minutes: 55));
      return newUrl;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todos los perros
  Future<void> getAllPerros() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notificación inmediata para mostrar el loading

    try {
      final nuevosPerros = await _perroRepository.getAllPerros();
      
      // Limpiar caché de URLs de perros que ya no existen
      _cleanupOrphanedCache(nuevosPerros);
      
      _perros = nuevosPerros;
      notifyListeners(); // Notificación inmediata cuando se obtienen los datos
      
      // Pre-cargar todas las URLs de imágenes en el caché de forma más agresiva
      await _preloadImageUrls(nuevosPerros);
      
      // Cargar imágenes inmediatamente en paralelo (sin delay)
      if (!_disposed) {
        loadAllImagesOptimized();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners(); // Notificación inmediata al finalizar
    }
  }

  /// Pre-carga URLs de imágenes para acceso inmediato
  Future<void> _preloadImageUrls(List<PerroModel> perros) async {
    if (_disposed) return;
    
    final futures = <Future<void>>[];
    
    for (final perro in perros) {
      if (perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          !perro.fotoPerro!.startsWith('http')) {
        
        // Pre-cargar URL en paralelo solo si no está en caché o está expirada
        if (!_isUrlCached(perro.fotoPerro!)) {
          futures.add(_preloadSingleImageUrl(perro.fotoPerro!));
        }
      }
    }
    
    // Ejecutar todas las pre-cargas en paralelo sin esperar
    if (futures.isNotEmpty) {
      Future.wait(futures).catchError((e) {
        // Ignorar errores de pre-carga para no bloquear la UI
        return <void>[];
      });
    }
  }

  /// Pre-carga una sola URL de imagen
  Future<void> _preloadSingleImageUrl(String fileName) async {
    try {
      final url = await _perroRepository.getSignedImageUrl(fileName);
      if (!_disposed) {
        _urlCache[fileName] = url;
        _urlCacheExpiry[fileName] = DateTime.now().add(const Duration(minutes: 55));
      }
    } catch (e) {
      // Ignorar errores de pre-carga
    }
  }

  /// Verifica si una URL está en caché y no está expirada
  bool _isUrlCached(String fileName) {
    if (!_urlCache.containsKey(fileName)) return false;
    
    final expiry = _urlCacheExpiry[fileName];
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      _urlCache.remove(fileName);
      _urlCacheExpiry.remove(fileName);
      return false;
    }
    
    return true;
  }

  /// Limpia del caché URLs de perros que ya no existen
  void _cleanupOrphanedCache(List<PerroModel> currentPerros) {
    // Obtener lista de nombres de archivos actuales
    final currentFileNames = currentPerros
        .where((p) => p.fotoPerro != null && !p.fotoPerro!.startsWith('http'))
        .map((p) => p.fotoPerro!)
        .toSet();
    
    // Eliminar del caché archivos que ya no están en la lista actual
    final keysToRemove = <String>[];
    for (final cachedFileName in _urlCache.keys) {
      if (!currentFileNames.contains(cachedFileName)) {
        keysToRemove.add(cachedFileName);
      }
    }
    
    for (final key in keysToRemove) {
      _urlCache.remove(key);
      _urlCacheExpiry.remove(key);
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
      
      // Pre-cargar la URL firmada en caché para carga inmediata
      final imageUrl = await _perroRepository.getSignedImageUrl(nombreArchivo);
      _urlCache[nombreArchivo] = imageUrl;
      _urlCacheExpiry[nombreArchivo] = DateTime.now().add(const Duration(minutes: 55));
      
      // Crear el perro con el nombre del archivo
      final perroConImagen = perro.copyWith(fotoPerro: nombreArchivo);
      await _perroRepository.createPerro(perroConImagen);
      
      // Recargar la lista (las imágenes se cargarán más rápido por el pre-cache)
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

  /// Actualiza un perro existente con nueva imagen
  Future<bool> updatePerroWithImage(PerroModel perro, File imagenFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener el perro original desde la base de datos para tener el nombre de archivo correcto
      final perroOriginal = await _perroRepository.getPerroById(perro.id!);
      if (perroOriginal == null) {
        throw Exception('No se pudo encontrar el perro en la base de datos');
      }
      
      // Obtener el nombre del archivo de imagen original (no la URL)
      String? imagenAntiguaArchivo;
      if (perroOriginal.fotoPerro != null && 
          perroOriginal.fotoPerro!.isNotEmpty && 
          !perroOriginal.fotoPerro!.startsWith('http')) {
        imagenAntiguaArchivo = perroOriginal.fotoPerro;
      }
      
      // Siempre generar un nuevo nombre único para evitar problemas de caché
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imagenFile.path.split('.').last.toLowerCase();
      final nombrePerroLimpio = perro.nombrePerro.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final nuevoNombreImagen = '${nombrePerroLimpio}_$timestamp.$extension';
      
      // Eliminar la imagen antigua del bucket si existe
      if (imagenAntiguaArchivo != null && 
          imagenAntiguaArchivo != nuevoNombreImagen) {
        try {
          await _perroRepository.deleteImage(imagenAntiguaArchivo);
        } catch (e) {
          // Continuar con la operación aunque falle la eliminación
        }
      }
      
      // Invalidar completamente el caché de la imagen antigua
      await invalidateImageCache(imagenAntiguaArchivo);
      
      // Subir la nueva imagen con el nuevo nombre
      final nombreImagen = await _perroRepository.uploadImage(imagenFile.path, nuevoNombreImagen);
      
      // Actualizar el perro en la base de datos con el nombre de la nueva imagen
      final perroConImagenActualizada = PerroModel(
        id: perro.id,
        nombrePerro: perro.nombrePerro,
        edadPerro: perro.edadPerro,
        sexoPerro: perro.sexoPerro,
        razaPerro: perro.razaPerro,
        pelajePerro: perro.pelajePerro,
        actividadPerro: perro.actividadPerro,
        estadoPerro: perro.estadoPerro,
        fotoPerro: nombreImagen, // Usar el nombre de la nueva imagen
        descripcionPerro: perro.descripcionPerro,
        estaturaPerro: perro.estaturaPerro,
        ingresoPerro: perro.ingresoPerro,
      );

      await _perroRepository.updatePerro(perro.id!, perroConImagenActualizada);
      
      // Actualizar inmediatamente el perro en la lista local para UI inmediata
      final index = _perros.indexWhere((p) => p.id == perro.id);
      if (index != -1) {
        // Generar URL firmada para la nueva imagen y actualizar caché
        final imageUrl = await _perroRepository.getSignedImageUrl(nombreImagen);
        _urlCache[nombreImagen] = imageUrl;
        _urlCacheExpiry[nombreImagen] = DateTime.now().add(const Duration(minutes: 50));
        
        // Actualizar el perro con la URL completa de la imagen para UI inmediata
        final perroConUrl = perroConImagenActualizada.copyWith(fotoPerro: imageUrl);
        _perros[index] = perroConUrl;
        notifyListeners(); // Notificación inmediata para actualizar UI
        
        // Invalidar completamente el caché de la imagen anterior
        await invalidateImageCache(imagenAntiguaArchivo);
      }
      
      // Recargar la lista para asegurar consistencia
      await getAllPerros();
      
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

    // Si no hay nombre de archivo de imagen válido, no hay nada que cargar
    if (perro.fotoPerro == null || 
        perro.fotoPerro!.isEmpty || 
        perro.fotoPerro!.startsWith('http')) {
      // Si es una URL, no necesita conversión
      if (perro.fotoPerro != null && perro.fotoPerro!.startsWith('http')) {
        return;
      }
      // Si no hay imagen o está vacía, marcar como sin imagen
      _updatePerro(
        index,
        perro.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'No hay imagen disponible',
        ),
      );
      return;
    }

    // Validar que el nombre del archivo parece válido
    if (!perro.fotoPerro!.contains('.') || perro.fotoPerro!.length < 5) {
      _updatePerro(
        index,
        perro.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'Nombre de archivo inválido',
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

      // Obtener la URL firmada desde caché
      final imageUrl = await _getCachedImageUrl(perro.fotoPerro!);

      if (!completer.isCompleted && imageUrl != null) {
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
      } else if (!completer.isCompleted) {
        // No se pudo obtener la URL
        _updatePerro(
          index,
          perro.copyWith(
            isLoadingImage: false,
            errorLoadingImage: 'No se pudo cargar la imagen',
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

  /// Limpia completamente el caché de URLs
  void clearImageCache() {
    _urlCache.clear();
    _urlCacheExpiry.clear();
  }

  /// Invalida completamente el caché de una imagen específica
  Future<void> invalidateImageCache(String? filename) async {
    if (filename == null || filename.isEmpty || filename.startsWith('http')) {
      return;
    }

    try {
      // Limpiar nuestro caché interno
      _urlCache.remove(filename);
      _urlCacheExpiry.remove(filename);
      
      // Obtener la URL firmada para limpiar el caché de CachedNetworkImage
      try {
        final imageUrl = await _perroRepository.getSignedImageUrl(filename);
        
        // Limpiar el caché de CachedNetworkImage
        final cachedImageManager = DefaultCacheManager();
        await cachedImageManager.removeFile(imageUrl);
      } catch (e) {
        // Error silencioso al invalidar caché externo
      }
    } catch (e) {
      // Error silencioso al invalidar caché
    }
  }

  /// Obtiene la URL firmada de una imagen de forma pública
  Future<String?> getImageUrl(String fileName) async {
    return await _getCachedImageUrl(fileName);
  }

  /// Carga optimizada de imágenes (más rápida y paralela)
  Future<void> loadAllImagesOptimized() async {
    if (_disposed) return;
    
    // No usar batch updating para permitir actualizaciones inmediatas
    final futures = <Future<void>>[];
    
    for (int i = 0; i < _perros.length; i++) {
      final perro = _perros[i];
      
      // Cargar todas las imágenes que necesiten carga
      if (perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          !perro.fotoPerro!.startsWith('http') &&
          !perro.isLoadingImage) {
        
        // Cargar cada imagen en paralelo con actualización inmediata
        futures.add(_loadPerroImageOptimized(i));
      }
    }
    
    // Ejecutar todas las cargas en paralelo
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Método optimizado para cargar imagen con actualización inmediata
  Future<void> _loadPerroImageOptimized(int index) async {
    if (index < 0 || index >= _perros.length || _disposed) return;

    final perro = _perros[index];

    // Si ya está cargando o ya tiene una URL válida, no hacer nada
    if (perro.isLoadingImage ||
        (perro.fotoPerro != null && perro.fotoPerro!.startsWith('http'))) {
      return;
    }

    // Si no hay nombre de archivo de imagen válido, no hay nada que cargar
    if (perro.fotoPerro == null || 
        perro.fotoPerro!.isEmpty || 
        !perro.fotoPerro!.contains('.') || 
        perro.fotoPerro!.length < 5) {
      return;
    }

    try {
      // Marcar como cargando y notificar inmediatamente
      _perros[index] = perro.copyWith(
        isLoadingImage: true,
        errorLoadingImage: null,
      );
      notifyListeners();

      // Obtener la URL firmada desde caché (esto es rápido si está cacheado)
      final imageUrl = await _getCachedImageUrl(perro.fotoPerro!);

      if (imageUrl != null && !_disposed && index < _perros.length) {
        // Actualizar el perro con la URL de la imagen y notificar inmediatamente
        _perros[index] = perro.copyWith(
          fotoPerro: imageUrl,
          isLoadingImage: false,
          errorLoadingImage: null,
        );
        notifyListeners(); // Actualización inmediata para mostrar la imagen
      } else if (!_disposed && index < _perros.length) {
        // No se pudo obtener la URL
        _perros[index] = perro.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'No se pudo cargar la imagen',
        );
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed && index < _perros.length) {
        // Manejar error
        _perros[index] = perro.copyWith(
          isLoadingImage: false,
          errorLoadingImage: 'Error al cargar imagen',
        );
        notifyListeners();
      }
    }
  }

  /// Pre-carga la imagen de un perro específico para edición rápida
  Future<void> preloadPerroImageForEditing(String? fileName) async {
    if (fileName == null || fileName.isEmpty || fileName.startsWith('http')) return;
    
    // Si ya está en caché y es válida, no hacer nada
    if (_isUrlCached(fileName)) return;
    
    try {
      // Pre-cargar la URL firmada
      await _preloadSingleImageUrl(fileName);
    } catch (e) {
      // Ignorar errores de pre-carga
    }
  }

  /// Inicialización optimizada para la primera carga
  Future<void> initializeWithOptimizedImageLoading() async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener perros sin cargar imágenes todavía
      final nuevosPerros = await _perroRepository.getAllPerros();
      
      // Limpiar caché de URLs de perros que ya no existen
      _cleanupOrphanedCache(nuevosPerros);
      
      _perros = nuevosPerros;
      notifyListeners(); // Mostrar la lista inmediatamente sin imágenes
      
      // Pre-cargar URLs en batch para los primeros 10 perros (pantalla visible + scroll inicial)
      final priorityPerros = nuevosPerros.take(10).toList();
      await _preloadImageUrls(priorityPerros);
      
      // Cargar imágenes prioritarias inmediatamente
      await _loadPriorityImages(priorityPerros);
      
      // Cargar el resto de imágenes en segundo plano
      if (nuevosPerros.length > 10) {
        final remainingPerros = nuevosPerros.skip(10).toList();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_disposed) {
            _preloadImageUrls(remainingPerros);
            _loadRemainingImages(remainingPerros, 10);
          }
        });
      }
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga imágenes prioritarias (primera pantalla)
  Future<void> _loadPriorityImages(List<PerroModel> priorityPerros) async {
    if (_disposed) return;
    
    final futures = <Future<void>>[];
    
    for (int i = 0; i < priorityPerros.length; i++) {
      final perro = priorityPerros[i];
      final globalIndex = _perros.indexWhere((p) => p.id == perro.id);
      
      if (globalIndex != -1 && perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          !perro.fotoPerro!.startsWith('http')) {
        futures.add(_loadPerroImageOptimized(globalIndex));
      }
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Carga imágenes restantes en segundo plano
  Future<void> _loadRemainingImages(List<PerroModel> remainingPerros, int startIndex) async {
    if (_disposed) return;
    
    for (int i = 0; i < remainingPerros.length; i++) {
      if (_disposed) break;
      
      final perro = remainingPerros[i];
      final globalIndex = _perros.indexWhere((p) => p.id == perro.id);
      
      if (globalIndex != -1 && perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          !perro.fotoPerro!.startsWith('http')) {
        await _loadPerroImageOptimized(globalIndex);
        
        // Pequeña pausa para no bloquear la UI
        if (i % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _imageLoadingOperations.clear();
    _urlCache.clear();
    _urlCacheExpiry.clear();
    super.dispose();
  }
}
