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
          .from('CampanaFirmas')
          .select('DniFirma, NombreFirma, MotivoFirma, FechaRegistro, ImagenFirma')
          .order('FechaRegistro', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final firmas = (response as List)
          .map((item) => FirmaModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Solo pre-cargar URLs en paralelo sin bloquear la respuesta (optimización)
      final firmasConImagen = firmas
          .where((f) => f.imagenFirma != null && f.imagenFirma!.isNotEmpty)
          .toList();
          
      if (firmasConImagen.isNotEmpty) {
        final imageFileNames = firmasConImagen.map((f) => f.imagenFirma!).toList();
        
        // Pre-cargar URLs en paralelo sin esperar (no bloquear)
        preloadImageUrls(imageFileNames);
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

  // Pre-cargar URLs de imágenes para acceso inmediato (optimizado para no bloquear)
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
      // Pre-cargar en paralelo sin esperar y sin bloquear el hilo principal
      Future.microtask(() async {
        try {
          await Future.wait(filesToPreload.map((fileName) async {
            try {
              await getSignedImageUrl(fileName);
            } catch (e) {
              // Ignorar errores de pre-carga individual
            }
          }));
        } catch (e) {
          // Ignorar errores de pre-carga para no bloquear la UI
        }
      });
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