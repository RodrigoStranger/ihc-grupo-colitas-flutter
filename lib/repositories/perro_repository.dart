import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/perro_model.dart';
import '../core/supabase.dart';

/// Repositorio para manejar operaciones CRUD de perros
class PerroRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Obtiene todos los perros (acceso público)
  Future<List<PerroModel>> getAllPerros() async {
    try {
      final response = await _supabase
          .from('Perros')
          .select()
          .order('IngresoPerro', ascending: false);

      return (response as List)
          .map((perro) => PerroModel.fromJson(perro))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener perros: $e');
    }
  }

  /// Obtiene un perro por ID (acceso público)
  Future<PerroModel?> getPerroById(String id) async {
    try {
      final response = await _supabase
          .from('Perros')
          .select()
          .eq('IdPerro', id)
          .maybeSingle();

      if (response != null) {
        return PerroModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener perro: $e');
    }
  }

  /// Obtiene perros por usuario (deprecado - usar getAllPerros)
  @Deprecated('Use getAllPerros() instead - no user filtering available')
  Future<List<PerroModel>> getPerrosByUser(String userId) async {
    // Como no tenemos user_id en la tabla, retornamos todos los perros
    return getAllPerros();
  }

  /// Crea un nuevo perro (solo usuarios autenticados)
  Future<PerroModel> createPerro(PerroModel perro) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Debe estar autenticado para crear un perro');
      }

      // Validar datos del perro
      if (!perro.isValid()) {
        throw Exception('Datos del perro inválidos');
      }

      final jsonData = perro.toJson();
      
      final response = await _supabase
          .from('Perros')
          .insert(jsonData)
          .select()
          .single();

      return PerroModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error de base de datos: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Error al crear perro: $e');
    } catch (e) {
      throw Exception('Error inesperado al crear perro: $e');
    }
  }

  /// Actualiza un perro existente (solo el usuario propietario)
  Future<PerroModel> updatePerro(String id, PerroModel perro) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Debe estar autenticado para actualizar un perro');
      }

      // Verificar que el perro existe
      final existingPerro = await getPerroById(id);
      if (existingPerro == null) {
        throw Exception('Perro no encontrado');
      }

      // Validar datos del perro
      if (!perro.isValid()) {
        throw Exception('Datos del perro inválidos');
      }

      final response = await _supabase
          .from('Perros')
          .update(perro.toJson())
          .eq('IdPerro', id)
          .select()
          .single();

      return PerroModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar perro: $e');
    }
  }

  /// Busca perros por criterios (acceso público)
  Future<List<PerroModel>> searchPerros({
    String? nombre,
    String? raza,
    String? sexo,
    String? estado,
  }) async {
    try {
      var query = _supabase.from('Perros').select();

      if (nombre != null && nombre.isNotEmpty) {
        query = query.ilike('NombrePerro', '%$nombre%');
      }
      if (raza != null && raza.isNotEmpty) {
        query = query.ilike('RazaPerro', '%$raza%');
      }
      if (sexo != null && sexo.isNotEmpty) {
        query = query.eq('SexoPerro', sexo);
      }
      if (estado != null && estado.isNotEmpty) {
        query = query.eq('EstadoPerro', estado);
      }

      final response = await query.order('IngresoPerro', ascending: false);

      return (response as List)
          .map((perro) => PerroModel.fromJson(perro))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar perros: $e');
    }
  }

  /// Sube una imagen al bucket de Supabase Storage
  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo de imagen no existe: $filePath');
      }

      // Verificar que el nombre del archivo no esté vacío
      if (fileName.isEmpty) {
        throw Exception('El nombre del archivo no puede estar vacío');
      }

      // Subir la imagen al bucket 'perros'
      await _supabase.storage
          .from('perros')
          .upload(fileName, file, 
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: true, // Permite sobrescribir si ya existe
                  ));

      // Retornar solo el nombre del archivo (como en firmas)
      return fileName;
    } on StorageException catch (e) {
      throw Exception('Error de storage: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Error al subir imagen: $e');
    } catch (e) {
      throw Exception('Error inesperado al subir imagen: $e');
    }
  }

  /// Sube una imagen desde bytes al bucket de Supabase Storage
  Future<String> uploadImageFromBytes(Uint8List bytes, String fileName) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Subir la imagen al bucket 'perros'
      await _supabase.storage
          .from('perros')
          .uploadBinary(fileName, bytes,
                       fileOptions: const FileOptions(
                         cacheControl: '3600',
                         upsert: true, // Permite sobrescribir si ya existe
                       ));

      // Retornar solo el nombre del archivo (como en firmas)
      return fileName;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Elimina una imagen del bucket de Supabase Storage
  Future<void> deleteImage(String fileName) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Limpiar el nombre del archivo si contiene rutas
      String cleanFileName = fileName;
      if (fileName.contains('/')) {
        cleanFileName = fileName.split('/').last;
      }

      // Verificar si el archivo existe antes de eliminarlo
      final files = await _supabase.storage.from('perros').list();
      final fileExists = files.any((file) => file.name == cleanFileName);
      
      if (!fileExists) {
        return; // No es error si no existe
      }

      // Eliminar el archivo
      await _supabase.storage
          .from('perros')
          .remove([cleanFileName]);
      
      // Verificar que se eliminó correctamente
      await Future.delayed(const Duration(milliseconds: 500));
      final filesAfter = await _supabase.storage.from('perros').list();
      final stillExists = filesAfter.any((file) => file.name == cleanFileName);
      
      if (stillExists) {
        throw Exception('No se pudo eliminar el archivo del bucket');
      }
      
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la URL firmada para la imagen de un perro (igual que en firmas)
  Future<String> getSignedImageUrl(String fileName) async {
    try {
      // Si contiene '/', extraer solo el nombre del archivo
      if (fileName.contains('/')) {
        fileName = fileName.split('/').last;
      }
      
      // Verificar que el archivo no esté vacío
      if (fileName.isEmpty) {
        throw Exception('Nombre de archivo vacío');
      }
      
      // Generar URL firmada (como en firmas) - 1 hora de duración
      return await _supabase.storage
          .from('perros')
          .createSignedUrl(fileName, 3600);
    } catch (e) {
      throw Exception('Error al obtener URL de imagen: $e');
    }
  }

  /// Lista todos los archivos en el bucket
  Future<List<String>> listBucketFiles() async {
    try {
      final response = await _supabase.storage
          .from('perros')
          .list();
      
      return response.map((file) => file.name).toList();
    } catch (e) {
      return [];
    }
  }
}
