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
  final Map<String, String> _urlCache = {};
  
  // Tiempo de expiración de la caché (1 hora en segundos)
  static const int _cacheExpiration = 3600;
  Timer? _cacheCleanupTimer;
  final Map<String, DateTime> _urlCacheTimestamps = {};

  FirmaRepository() {
    // Limpiar caché cada 5 minutos
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 5), 
      (_) => _cleanupExpiredCache()
    );
  }

  void dispose() {
    _cacheCleanupTimer?.cancel();
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _urlCacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp).inSeconds > _cacheExpiration) {
        _urlCache.remove(key);
        return true;
      }
      return false;
    });
  }

  // Obtener URLs firmadas en lote
  Future<Map<String, String>> _getSignedUrls(List<String> fileNames) async {
    final Map<String, String> result = {};
    final List<String> filesToFetch = [];
    final now = DateTime.now();

    // Filtrar archivos que ya están en caché y no han expirado
    for (final fileName in fileNames) {
      final cacheKey = fileName.contains('/') ? fileName.split('/').last : fileName;
      if (_urlCache.containsKey(cacheKey) && 
          _urlCacheTimestamps[cacheKey] != null &&
          now.difference(_urlCacheTimestamps[cacheKey]!).inSeconds < _cacheExpiration) {
        result[fileName] = _urlCache[cacheKey]!;
      } else {
        filesToFetch.add(cacheKey);
      }
    }

    // Obtener URLs firmadas en paralelo
    if (filesToFetch.isNotEmpty) {
      final urls = await Future.wait(
        filesToFetch.map((file) => getSignedImageUrl(file))
      );

      // Actualizar caché
      for (int i = 0; i < filesToFetch.length; i++) {
        final cacheKey = filesToFetch[i];
        final url = urls[i];
        _urlCache[cacheKey] = url;
        _urlCacheTimestamps[cacheKey] = now;
        
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

  // Obtener URL firmada para un solo archivo
  Future<String> getSignedImageUrl(String fileName) async {
    if (fileName.contains('/')) {
      fileName = fileName.split('/').last;
    }
    
    return await _supabase.storage
        .from('firmas')
        .createSignedUrl(fileName, _cacheExpiration);
  }

  // Obtener firmas con paginación
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
          
      // Obtener URLs firmadas en lote
      if (firmasConImagen.isNotEmpty) {
        final imageUrls = await _getSignedUrls(
          firmasConImagen.map((f) => f.imagenFirma!).toList()
        );
        
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
}