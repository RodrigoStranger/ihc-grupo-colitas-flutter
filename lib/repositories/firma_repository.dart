import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/firma_model.dart';
import '../core/supabase.dart';

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}

class FirmaRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Cache de URLs firmadas para evitar regenerarlas constantemente
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlCacheExpiry = {};
  
  // Tiempo de expiración de la caché (55 minutos para ser consistente con perros)
  static const int _cacheExpiration = 3300; // 55 minutos en segundos
  Timer? _cacheCleanupTimer;

  FirmaRepository() {
    // Limpiar caché cada 10 minutos
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 10), 
      (_) => _cleanupExpiredCache()
    );
  }

  void dispose() {
    _cacheCleanupTimer?.cancel();
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _urlCacheExpiry.removeWhere((key, expiry) {
      if (now.isAfter(expiry)) {
        _urlCache.remove(key);
        return true;
      }
      return false;
    });
  }

  // Obtener URLs firmadas en lote con cache optimizado
  Future<Map<String, String>> _getSignedUrls(List<String> fileNames) async {
    final Map<String, String> result = {};
    final List<String> filesToFetch = [];
    final now = DateTime.now();

    // Filtrar archivos que ya están en caché y no han expirado
    for (final fileName in fileNames) {
      final cacheKey = fileName.contains('/') ? fileName.split('/').last : fileName;
      if (_urlCache.containsKey(cacheKey) && 
          _urlCacheExpiry[cacheKey] != null &&
          now.isBefore(_urlCacheExpiry[cacheKey]!)) {
        result[fileName] = _urlCache[cacheKey]!;
      } else {
        // Limpiar entrada expirada
        _urlCache.remove(cacheKey);
        _urlCacheExpiry.remove(cacheKey);
        filesToFetch.add(cacheKey);
      }
    }

    // Obtener URLs firmadas en paralelo para archivos no cacheados
    if (filesToFetch.isNotEmpty) {
      final urls = await Future.wait(
        filesToFetch.map((file) => _getSignedImageUrlDirect(file))
      );

      // Actualizar caché con nuevas URLs
      for (int i = 0; i < filesToFetch.length; i++) {
        final cacheKey = filesToFetch[i];
        final url = urls[i];
        _urlCache[cacheKey] = url;
        _urlCacheExpiry[cacheKey] = now.add(Duration(seconds: _cacheExpiration));
        
        // Asignar URL al archivo original que podría tener ruta completa
        final originalFileName = fileNames.firstWhere(
          (f) => f.contains(cacheKey),
          orElse: () => cacheKey
        );
        result[originalFileName] = url;
      }
    }

    return result;
  }

  // Obtener URL firmada directamente desde Supabase (sin cache)
  Future<String> _getSignedImageUrlDirect(String fileName) async {
    if (fileName.contains('/')) {
      fileName = fileName.split('/').last;
    }
    
    return await _supabase.storage
        .from('firmas')
        .createSignedUrl(fileName, _cacheExpiration);
  }

  // Obtener URL firmada para un solo archivo (con cache)
  Future<String> getSignedImageUrl(String fileName) async {
    final cacheKey = fileName.contains('/') ? fileName.split('/').last : fileName;
    
    // Verificar si está en caché y no ha expirado
    if (_urlCache.containsKey(cacheKey) && 
        _urlCacheExpiry[cacheKey] != null &&
        DateTime.now().isBefore(_urlCacheExpiry[cacheKey]!)) {
      return _urlCache[cacheKey]!;
    }
    
    // Limpiar entrada expirada
    _urlCache.remove(cacheKey);
    _urlCacheExpiry.remove(cacheKey);
    
    // Obtener nueva URL
    final url = await _getSignedImageUrlDirect(cacheKey);
    
    // Guardar en caché
    _urlCache[cacheKey] = url;
    _urlCacheExpiry[cacheKey] = DateTime.now().add(Duration(seconds: _cacheExpiration));
    
    return url;
  }

  // Obtener firmas con paginación y carga optimizada de imágenes
  Future<List<FirmaModel>> getFirmas({int page = 0, int pageSize = 20}) async {
    try {
      // Verificar autenticación
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw StorageException('Usuario no autenticado');
      }
      
      // Obtener firmas de la base de datos con paginación
      final response = await _supabase
          .from('CampañaFirmas')
          .select('DniFirma, NombreFirma, MotivoFirma, FechaRegistro, ImagenFirma')
          .order('FechaRegistro', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final firmas = (response as List)
          .map((item) => FirmaModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Filtrar firmas con imagen
      final firmasConImagen = firmas
          .where((f) => f.imagenFirma != null && f.imagenFirma!.isNotEmpty)
          .toList();
          
      // Pre-cargar URLs en paralelo para acceso inmediato
      if (firmasConImagen.isNotEmpty) {
        final imageFileNames = firmasConImagen.map((f) => f.imagenFirma!).toList();
        
        // Pre-cargar todas las URLs en paralelo
        preloadImageUrls(imageFileNames);
        
        // Obtener URLs firmadas en lote (desde caché si están disponibles)
        final imageUrls = await _getSignedUrls(imageFileNames);
        
        // Actualizar firmas con las URLs
        for (int i = 0; i < firmas.length; i++) {
          final firma = firmas[i];
          if (firma.imagenFirma != null && firma.imagenFirma!.isNotEmpty) {
            final url = imageUrls[firma.imagenFirma!];
            if (url != null) {
              firmas[i] = firma.copyWith(imagenFirma: url);
            }
          }
        }
      }
      
      return firmas;
    } catch (e) {
      rethrow;
    }
  }
  
  // Método para precargar las siguientes páginas
  Future<void> preloadNextPage(int currentPage, {int pageSize = 20}) async {
    try {
      await getFirmas(page: currentPage + 1, pageSize: pageSize);
    } catch (_) {
      // Ignorar errores en precarga
    }
  }

  // Pre-cargar URLs de imágenes para acceso inmediato
  Future<void> preloadImageUrls(List<String> fileNames) async {
    if (fileNames.isEmpty) return;
    
    final List<String> filesToPreload = [];
    final now = DateTime.now();
    
    for (final fileName in fileNames) {
      final cacheKey = fileName.contains('/') ? fileName.split('/').last : fileName;
      
      // Solo pre-cargar si no está en caché o está expirado
      if (!_urlCache.containsKey(cacheKey) || 
          _urlCacheExpiry[cacheKey] == null ||
          now.isAfter(_urlCacheExpiry[cacheKey]!)) {
        filesToPreload.add(cacheKey);
      }
    }
    
    if (filesToPreload.isNotEmpty) {
      try {
        // Pre-cargar en paralelo sin esperar
        Future.wait(filesToPreload.map((fileName) async {
          try {
            await getSignedImageUrl(fileName);
          } catch (e) {
            // Ignorar errores de pre-carga individual
          }
        })).catchError((e) {
          // Ignorar errores de pre-carga para no bloquear la UI
          return <Null>[];
        });
      } catch (e) {
        // Ignorar errores de pre-carga
      }
    }
  }

  // Limpiar caché de una imagen específica
  void invalidateImageCache(String? fileName) {
    if (fileName == null || fileName.isEmpty) return;
    
    final cacheKey = fileName.contains('/') ? fileName.split('/').last : fileName;
    _urlCache.remove(cacheKey);
    _urlCacheExpiry.remove(cacheKey);
  }

  // Limpiar todo el caché
  void clearImageCache() {
    _urlCache.clear();
    _urlCacheExpiry.clear();
  }
}