/// Modelo que representa un perro en el sistema
class PerroModel {
  final String? id; // ID único del perro (nullable para nuevos registros)
  final String nombrePerro;
  final int edadPerro;
  final String sexoPerro;
  final String razaPerro;
  final String pelajePerro;
  final String actividadPerro;
  final String estadoPerro;
  final String? fotoPerro; // Nombre del archivo de imagen (nombrePerro.png)
  final String descripcionPerro;
  final DateTime ingresoPerro;
  final String? userId; // ID del usuario que creó el registro (para control de acceso)
  final bool isLoadingImage; // Para manejar el estado de carga de la imagen
  final String? errorLoadingImage; // Para manejar errores de carga de imagen

  const PerroModel({
    this.id,
    required this.nombrePerro,
    required this.edadPerro,
    required this.sexoPerro,
    required this.razaPerro,
    required this.pelajePerro,
    required this.actividadPerro,
    required this.estadoPerro,
    this.fotoPerro,
    required this.descripcionPerro,
    required this.ingresoPerro,
    this.userId,
    this.isLoadingImage = false,
    this.errorLoadingImage,
  });

  /// Valida que el modelo tenga datos válidos
  bool isValid() {
    return nombrePerro.isNotEmpty &&
           edadPerro >= 0 && edadPerro <= 25 &&
           sexoPerro.isNotEmpty &&
           razaPerro.isNotEmpty &&
           pelajePerro.isNotEmpty &&
           actividadPerro.isNotEmpty &&
           estadoPerro.isNotEmpty &&
           descripcionPerro.isNotEmpty;
  }

  /// Crea un PerroModel desde datos de Supabase
  factory PerroModel.fromJson(Map<String, dynamic> json) {
    return PerroModel(
      id: json['id']?.toString(),
      nombrePerro: json['NombrePerro'] ?? '',
      edadPerro: json['EdadPerro'] ?? 0,
      sexoPerro: json['SexoPerro'] ?? '',
      razaPerro: json['RazaPerro'] ?? '',
      pelajePerro: json['PelajePerro'] ?? '',
      actividadPerro: json['ActividadPerro'] ?? '',
      estadoPerro: json['EstadoPerro'] ?? '',
      fotoPerro: json['FotoPerro'] as String?,
      descripcionPerro: json['DescripcionPerro'] ?? '',
      ingresoPerro: json['IngresoPerro'] != null 
          ? DateTime.parse(json['IngresoPerro']) 
          : DateTime.now(),
      userId: json['user_id'],
      isLoadingImage: false,
    );
  }

  /// Convierte el modelo a Map para enviar a Supabase
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'NombrePerro': nombrePerro,
      'EdadPerro': edadPerro,
      'SexoPerro': sexoPerro,
      'RazaPerro': razaPerro,
      'PelajePerro': pelajePerro,
      'ActividadPerro': actividadPerro,
      'EstadoPerro': estadoPerro,
      'FotoPerro': fotoPerro,
      'DescripcionPerro': descripcionPerro,
      'IngresoPerro': ingresoPerro.toIso8601String(),
      'user_id': userId,
    };
    
    // Solo incluir el ID si no es null (para actualizaciones)
    if (id != null) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Crea una copia del modelo con algunos campos modificados
  PerroModel copyWith({
    String? id,
    String? nombrePerro,
    int? edadPerro,
    String? sexoPerro,
    String? razaPerro,
    String? pelajePerro,
    String? actividadPerro,
    String? estadoPerro,
    String? fotoPerro,
    String? descripcionPerro,
    DateTime? ingresoPerro,
    String? userId,
    bool? isLoadingImage,
    String? errorLoadingImage,
  }) {
    return PerroModel(
      id: id ?? this.id,
      nombrePerro: nombrePerro ?? this.nombrePerro,
      edadPerro: edadPerro ?? this.edadPerro,
      sexoPerro: sexoPerro ?? this.sexoPerro,
      razaPerro: razaPerro ?? this.razaPerro,
      pelajePerro: pelajePerro ?? this.pelajePerro,
      actividadPerro: actividadPerro ?? this.actividadPerro,
      estadoPerro: estadoPerro ?? this.estadoPerro,
      fotoPerro: fotoPerro ?? this.fotoPerro,
      descripcionPerro: descripcionPerro ?? this.descripcionPerro,
      ingresoPerro: ingresoPerro ?? this.ingresoPerro,
      userId: userId ?? this.userId,
      isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      errorLoadingImage: errorLoadingImage ?? this.errorLoadingImage,
    );
  }

  @override
  String toString() {
    return 'PerroModel(id: $id, nombrePerro: $nombrePerro, edadPerro: $edadPerro, sexoPerro: $sexoPerro, razaPerro: $razaPerro, pelajePerro: $pelajePerro, actividadPerro: $actividadPerro, estadoPerro: $estadoPerro, fotoPerro: $fotoPerro, descripcionPerro: $descripcionPerro, ingresoPerro: $ingresoPerro, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PerroModel &&
      other.id == id &&
      other.nombrePerro == nombrePerro &&
      other.edadPerro == edadPerro &&
      other.sexoPerro == sexoPerro &&
      other.razaPerro == razaPerro &&
      other.pelajePerro == pelajePerro &&
      other.actividadPerro == actividadPerro &&
      other.estadoPerro == estadoPerro &&
      other.fotoPerro == fotoPerro &&
      other.descripcionPerro == descripcionPerro &&
      other.ingresoPerro == ingresoPerro &&
      other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      nombrePerro.hashCode ^
      edadPerro.hashCode ^
      sexoPerro.hashCode ^
      razaPerro.hashCode ^
      pelajePerro.hashCode ^
      actividadPerro.hashCode ^
      estadoPerro.hashCode ^
      fotoPerro.hashCode ^
      descripcionPerro.hashCode ^
      ingresoPerro.hashCode ^
      userId.hashCode;
  }
}
