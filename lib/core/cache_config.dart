import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const key = 'perros_images_cache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 48), // Más tiempo antes de considerar obsoleto
      maxNrOfCacheObjects: 500, // Más imágenes en caché
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
  
  // Cache manager especial para thumbnails más pequeños
  static const thumbnailKey = 'perros_thumbnails_cache';
  
  static CacheManager thumbnailInstance = CacheManager(
    Config(
      thumbnailKey,
      stalePeriod: const Duration(days: 7), // Thumbnails duran más tiempo
      maxNrOfCacheObjects: 1000, // Más thumbnails en caché
      repo: JsonCacheInfoRepository(databaseName: thumbnailKey),
      fileService: HttpFileService(),
    ),
  );
}
