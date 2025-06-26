import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perro_model.dart';
import '../core/supabase.dart';

/// Repositorio para manejar operaciones CRUD de perros
class PerroRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Duración del caché para URLs firmadas (24 horas)
  static const int _cacheExpiration = 24 * 60 * 60;

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
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return PerroModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener perro: $e');
    }
  }

  /// Obtiene perros por usuario (solo para usuarios autenticados)
  Future<List<PerroModel>> getPerrosByUser(String userId) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('Perros')
          .select()
          .eq('user_id', userId)
          .order('IngresoPerro', ascending: false);

      return (response as List)
          .map((perro) => PerroModel.fromJson(perro))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener perros del usuario: $e');
    }
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

      // Agregar el ID del usuario al perro
      final perroWithUser = perro.copyWith(userId: user.id);
      
      final response = await _supabase
          .from('Perros')
          .insert(perroWithUser.toJson())
          .select()
          .single();

      return PerroModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear perro: $e');
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

      // Verificar que el perro existe y pertenece al usuario
      final existingPerro = await getPerroById(id);
      if (existingPerro == null) {
        throw Exception('Perro no encontrado');
      }
      
      if (existingPerro.userId != user.id) {
        throw Exception('No tiene permisos para actualizar este perro');
      }

      // Validar datos del perro
      if (!perro.isValid()) {
        throw Exception('Datos del perro inválidos');
      }

      final response = await _supabase
          .from('Perros')
          .update(perro.toJson())
          .eq('id', id)
          .eq('user_id', user.id) // Doble verificación de seguridad
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

  /// Obtiene la URL firmada para la imagen de un perro
  Future<String> getSignedImageUrl(String fileName) async {
    if (fileName.contains('/')) {
      fileName = fileName.split('/').last;
    }
    
    return await _supabase.storage
        .from('perros')
        .createSignedUrl(fileName, _cacheExpiration);
  }
}
