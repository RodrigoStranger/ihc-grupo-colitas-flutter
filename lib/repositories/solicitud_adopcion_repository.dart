import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitud_adopcion_model.dart';
import '../core/supabase.dart';

class SolicitudAdopcionException implements Exception {
  final String message;
  SolicitudAdopcionException(this.message);
  @override
  String toString() => 'SolicitudAdopcionException: $message';
}

class SolicitudAdopcionRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Cache de URLs firmadas para evitar regenerarlas constantemente
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlCacheExpiry = {};
  
  // Tiempo de expiración de la caché (55 minutos para ser consistente)
  static const int _cacheExpiration = 3300; // 55 minutos en segundos
  Timer? _cacheCleanupTimer;

  SolicitudAdopcionRepository() {
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
        .from('perros') // Usar el bucket de perros para las fotos
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

  // Obtener solicitudes de adopción con paginación y carga optimizada de imágenes
  Future<List<SolicitudAdopcionModel>> getSolicitudesAdopcion({int page = 0, int pageSize = 20}) async {
    try {
      // Verificar autenticación
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw SolicitudAdopcionException('Usuario no autenticado');
      }
      
      // Obtener solicitudes con información del perro mediante JOIN
      final response = await _supabase
          .from('SolicitudesAdopcion')
          .select('''
            IdSolicitanteAdopcion,
            NombreSolicitanteAdopcion,
            Numero1SolicitanteAdopcion,
            Numero2SolicitanteAdopcion,
            DescripcionSolicitanteAdopcion,
            EstadoSolicitanteAdopcion,
            FechaSolicitanteAdopcion,
            IdPerro,
            Perros(NombrePerro, FotoPerro)
          ''')
          .order('FechaSolicitanteAdopcion', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final solicitudes = (response as List).map((item) {
        final perroData = item['Perros'] as Map<String, dynamic>?;
        final solicitudData = Map<String, dynamic>.from(item);
        
        // Agregar información del perro al mapa principal
        if (perroData != null) {
          solicitudData['NombrePerro'] = perroData['NombrePerro'];
          solicitudData['FotoPerro'] = perroData['FotoPerro'];
        }
        
        return SolicitudAdopcionModel.fromMap(solicitudData);
      }).toList();

      // Pre-cargar URLs de imágenes para solicitudes que tienen foto de perro
      final solicitudesConImagen = solicitudes
          .where((s) => s.fotoPerro != null && s.fotoPerro!.isNotEmpty)
          .toList();
          
      if (solicitudesConImagen.isNotEmpty) {
        final imageFileNames = solicitudesConImagen.map((s) => s.fotoPerro!).toList();
        
        // Pre-cargar todas las URLs en paralelo
        preloadImageUrls(imageFileNames);
        
        // Actualizar solicitudes con las URLs firmadas
        for (int i = 0; i < solicitudes.length; i++) {
          final solicitud = solicitudes[i];
          if (solicitud.fotoPerro != null && solicitud.fotoPerro!.isNotEmpty) {
            try {
              final url = await getSignedImageUrl(solicitud.fotoPerro!);
              solicitudes[i] = solicitud.copyWith(fotoPerro: url);
            } catch (e) {
              // Si no se puede obtener la URL, mantener el nombre del archivo
            }
          }
        }
      }
      
      return solicitudes;
    } catch (e) {
      rethrow;
    }
  }

  // Aceptar solicitud de adopción (actualizar estado de solicitud y perro)
  Future<bool> aceptarSolicitud(String solicitudId, String perroId) async {
    try {
      // Verificar autenticación
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw SolicitudAdopcionException('Usuario no autenticado');
      }

      // Actualizar el estado de la solicitud aceptada a "Aceptado"
      await _supabase
          .from('SolicitudesAdopcion')
          .update({'EstadoSolicitanteAdopcion': 'Aceptado'})
          .eq('IdSolicitanteAdopcion', int.parse(solicitudId));

      // Actualizar el estado del perro a "Adoptado"
      await _supabase
          .from('Perros')
          .update({'EstadoPerro': 'Adoptado'})
          .eq('IdPerro', int.parse(perroId));

      // Rechazar automáticamente todas las demás solicitudes pendientes del mismo perro
      await _supabase
          .from('SolicitudesAdopcion')
          .update({'EstadoSolicitanteAdopcion': 'Rechazado'})
          .eq('IdPerro', int.parse(perroId))
          .neq('IdSolicitanteAdopcion', int.parse(solicitudId))
          .eq('EstadoSolicitanteAdopcion', 'Pendiente');

      return true;
    } catch (e) {
      throw SolicitudAdopcionException('Error al aceptar solicitud: ${e.toString()}');
    }
  }

  // Rechazar solicitud de adopción
  Future<bool> rechazarSolicitud(String solicitudId) async {
    try {
      // Verificar autenticación
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw SolicitudAdopcionException('Usuario no autenticado');
      }

      // Actualizar el estado de la solicitud a "Rechazado"
      await _supabase
          .from('SolicitudesAdopcion')
          .update({'EstadoSolicitanteAdopcion': 'Rechazado'})
          .eq('IdSolicitanteAdopcion', int.parse(solicitudId));

      return true;
    } catch (e) {
      throw SolicitudAdopcionException('Error al rechazar solicitud: ${e.toString()}');
    }
  }

  // Método para precargar las siguientes páginas
  Future<void> preloadNextPage(int currentPage, {int pageSize = 20}) async {
    try {
      await getSolicitudesAdopcion(page: currentPage + 1, pageSize: pageSize);
    } catch (_) {
      // Ignorar errores en precarga
    }
  }
}
