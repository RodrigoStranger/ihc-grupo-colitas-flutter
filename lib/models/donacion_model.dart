class Donacion {
  final int?
  idSolicitanteDonacion; // Puede ser null si es una nueva donación aún no guardada
  final String nombreSolicitanteDonacion;
  final String numero1SolicitanteDonacion;
  final String? numero2SolicitanteDonacion; // Puede ser null
  final String descripcionSolicitanteDonacion;
  final String estadoSolicitanteDonacion;
  final DateTime fechaSolicitanteDonacion;

  Donacion({
    this.idSolicitanteDonacion,
    required this.nombreSolicitanteDonacion,
    required this.numero1SolicitanteDonacion,
    this.numero2SolicitanteDonacion,
    required this.descripcionSolicitanteDonacion,
    required this.estadoSolicitanteDonacion,
    required this.fechaSolicitanteDonacion,
  });

  // Constructor factory para crear una instancia desde un JSON (útil para API responses)
  factory Donacion.fromJson(Map<String, dynamic> json) {
    return Donacion(
      idSolicitanteDonacion: json['IdSolicitanteDonacion'] as int?,
      nombreSolicitanteDonacion:
          json['NombreSolicitanteDonacion']
              as String, // Ajusta si el nombre del campo en el JSON es diferente
      numero1SolicitanteDonacion: json['Numero1SolicitanteDonacion'] as String,
      numero2SolicitanteDonacion: json['Numero2SolicitanteDonacion'] as String?,
      descripcionSolicitanteDonacion:
          json['DescripcionSolicitanteDonacion'] as String,
      estadoSolicitanteDonacion: json['EstadoSolicitanteDonacion'] as String,
      fechaSolicitanteDonacion: DateTime.parse(
        json['FechaSolicitanteDonacion'] as String,
      ),
    );
  }

  // Método para convertir la instancia a un JSON (útil para API requests)
  Map<String, dynamic> toJson() {
    return {
      // No incluimos 'IdSolicitanteDonacion' si es null (para creación)
      if (idSolicitanteDonacion != null)
        'IdSolicitanteDonacion': idSolicitanteDonacion,
      'NombreSolicitanteDonacion': nombreSolicitanteDonacion,
      'Numero1SolicitanteDonacion': numero1SolicitanteDonacion,
      if (numero2SolicitanteDonacion != null)
        'Numero2SolicitanteDonacion': numero2SolicitanteDonacion,
      'DescripcionSolicitanteDonacion': descripcionSolicitanteDonacion,
      'EstadoSolicitanteDonacion': estadoSolicitanteDonacion,
      // Formatear la fecha a ISO 8601 string, que es común para APIs
      'FechaSolicitanteDonacion': fechaSolicitanteDonacion.toIso8601String(),
    };
  }

  // Opcional: Un método copyWith para facilitar la creación de nuevas instancias basadas en una existente
  Donacion copyWith({
    int? idSolicitanteDonacion,
    String? nombreSolicitanteDonacion,
    String? numero1SolicitanteDonacion,
    String? numero2SolicitanteDonacion,
    String? descripcionSolicitanteDonacion,
    String? estadoSolicitanteDonacion,
    DateTime? fechaSolicitanteDonacion,
  }) {
    return Donacion(
      idSolicitanteDonacion:
          idSolicitanteDonacion ?? this.idSolicitanteDonacion,
      nombreSolicitanteDonacion:
          nombreSolicitanteDonacion ?? this.nombreSolicitanteDonacion,
      numero1SolicitanteDonacion:
          numero1SolicitanteDonacion ?? this.numero1SolicitanteDonacion,
      numero2SolicitanteDonacion:
          numero2SolicitanteDonacion ?? this.numero2SolicitanteDonacion,
      descripcionSolicitanteDonacion:
          descripcionSolicitanteDonacion ?? this.descripcionSolicitanteDonacion,
      estadoSolicitanteDonacion:
          estadoSolicitanteDonacion ?? this.estadoSolicitanteDonacion,
      fechaSolicitanteDonacion:
          fechaSolicitanteDonacion ?? this.fechaSolicitanteDonacion,
    );
  }

  // Opcional: Sobrescribir toString, equals y hashCode para mejor debugging y uso en colecciones
  @override
  String toString() {
    return 'Donacion(idSolicitanteDonacion: $idSolicitanteDonacion, nombreSolicitanteDonacion: $nombreSolicitanteDonacion, estadoSolicitanteDonacion: $estadoSolicitanteDonacion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Donacion &&
        other.idSolicitanteDonacion == idSolicitanteDonacion &&
        other.nombreSolicitanteDonacion == nombreSolicitanteDonacion &&
        other.numero1SolicitanteDonacion == numero1SolicitanteDonacion &&
        other.numero2SolicitanteDonacion == numero2SolicitanteDonacion &&
        other.descripcionSolicitanteDonacion ==
            descripcionSolicitanteDonacion &&
        other.estadoSolicitanteDonacion == estadoSolicitanteDonacion &&
        other.fechaSolicitanteDonacion == fechaSolicitanteDonacion;
  }

  @override
  int get hashCode {
    return idSolicitanteDonacion.hashCode ^
        nombreSolicitanteDonacion.hashCode ^
        numero1SolicitanteDonacion.hashCode ^
        numero2SolicitanteDonacion.hashCode ^
        descripcionSolicitanteDonacion.hashCode ^
        estadoSolicitanteDonacion.hashCode ^
        fechaSolicitanteDonacion.hashCode;
  }
}
