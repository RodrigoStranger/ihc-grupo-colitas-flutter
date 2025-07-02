class Voluntariado {
  final int? idSolicitanteVoluntariado; // Puede ser null si es una nueva solicitud aún no guardada
  final String nombreSolicitanteVoluntariado;
  final String numero1SolicitanteVoluntariado;
  final String? numero2SolicitanteVoluntariado; // Puede ser null
  final String descripcionSolicitanteVoluntariado;
  final String estadoSolicitanteVoluntariado;
  final DateTime fechaSolicitanteVoluntariado;

  Voluntariado({
    this.idSolicitanteVoluntariado,
    required this.nombreSolicitanteVoluntariado,
    required this.numero1SolicitanteVoluntariado,
    this.numero2SolicitanteVoluntariado,
    required this.descripcionSolicitanteVoluntariado,
    required this.estadoSolicitanteVoluntariado,
    required this.fechaSolicitanteVoluntariado,
  });

  // Constructor factory para crear una instancia desde un JSON (útil para API responses)
  factory Voluntariado.fromJson(Map<String, dynamic> json) {
    return Voluntariado(
      idSolicitanteVoluntariado: json['IdSolicitanteVoluntariado'] as int?,
      nombreSolicitanteVoluntariado: json['NombreSolicitanteVoluntariado'] as String,
      numero1SolicitanteVoluntariado: json['Numero1SolicitanteVoluntariado'] as String,
      numero2SolicitanteVoluntariado: json['Numero2SolicitanteVoluntariado'] as String?,
      descripcionSolicitanteVoluntariado: json['DescripcionSolicitanteVoluntariado'] as String,
      estadoSolicitanteVoluntariado: json['EstadoSolicitanteVoluntariado'] as String,
      fechaSolicitanteVoluntariado: DateTime.parse(
        json['FechaSolicitanteVoluntariado'] as String,
      ),
    );
  }

  // Método para convertir la instancia a un JSON (útil para API requests)
  Map<String, dynamic> toJson() {
    return {
      // No incluimos 'IdSolicitanteVoluntariado' si es null (para creación)
      if (idSolicitanteVoluntariado != null)
        'IdSolicitanteVoluntariado': idSolicitanteVoluntariado,
      'NombreSolicitanteVoluntariado': nombreSolicitanteVoluntariado,
      'Numero1SolicitanteVoluntariado': numero1SolicitanteVoluntariado,
      if (numero2SolicitanteVoluntariado != null)
        'Numero2SolicitanteVoluntariado': numero2SolicitanteVoluntariado,
      'DescripcionSolicitanteVoluntariado': descripcionSolicitanteVoluntariado,
      'EstadoSolicitanteVoluntariado': estadoSolicitanteVoluntariado,
      'FechaSolicitanteVoluntariado': fechaSolicitanteVoluntariado.toIso8601String(),
    };
  }

  // Método copyWith para crear copias con valores modificados
  Voluntariado copyWith({
    int? idSolicitanteVoluntariado,
    String? nombreSolicitanteVoluntariado,
    String? numero1SolicitanteVoluntariado,
    String? numero2SolicitanteVoluntariado,
    String? descripcionSolicitanteVoluntariado,
    String? estadoSolicitanteVoluntariado,
    DateTime? fechaSolicitanteVoluntariado,
  }) {
    return Voluntariado(
      idSolicitanteVoluntariado:
          idSolicitanteVoluntariado ?? this.idSolicitanteVoluntariado,
      nombreSolicitanteVoluntariado:
          nombreSolicitanteVoluntariado ?? this.nombreSolicitanteVoluntariado,
      numero1SolicitanteVoluntariado:
          numero1SolicitanteVoluntariado ?? this.numero1SolicitanteVoluntariado,
      numero2SolicitanteVoluntariado:
          numero2SolicitanteVoluntariado ?? this.numero2SolicitanteVoluntariado,
      descripcionSolicitanteVoluntariado: descripcionSolicitanteVoluntariado ??
          this.descripcionSolicitanteVoluntariado,
      estadoSolicitanteVoluntariado:
          estadoSolicitanteVoluntariado ?? this.estadoSolicitanteVoluntariado,
      fechaSolicitanteVoluntariado:
          fechaSolicitanteVoluntariado ?? this.fechaSolicitanteVoluntariado,
    );
  }

  @override
  String toString() {
    return 'Voluntariado{idSolicitanteVoluntariado: $idSolicitanteVoluntariado, nombreSolicitanteVoluntariado: $nombreSolicitanteVoluntariado, numero1SolicitanteVoluntariado: $numero1SolicitanteVoluntariado, numero2SolicitanteVoluntariado: $numero2SolicitanteVoluntariado, descripcionSolicitanteVoluntariado: $descripcionSolicitanteVoluntariado, estadoSolicitanteVoluntariado: $estadoSolicitanteVoluntariado, fechaSolicitanteVoluntariado: $fechaSolicitanteVoluntariado}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Voluntariado &&
          runtimeType == other.runtimeType &&
          idSolicitanteVoluntariado == other.idSolicitanteVoluntariado &&
          nombreSolicitanteVoluntariado == other.nombreSolicitanteVoluntariado &&
          numero1SolicitanteVoluntariado == other.numero1SolicitanteVoluntariado &&
          numero2SolicitanteVoluntariado == other.numero2SolicitanteVoluntariado &&
          descripcionSolicitanteVoluntariado ==
              other.descripcionSolicitanteVoluntariado &&
          estadoSolicitanteVoluntariado == other.estadoSolicitanteVoluntariado &&
          fechaSolicitanteVoluntariado == other.fechaSolicitanteVoluntariado;

  @override
  int get hashCode =>
      idSolicitanteVoluntariado.hashCode ^
      nombreSolicitanteVoluntariado.hashCode ^
      numero1SolicitanteVoluntariado.hashCode ^
      numero2SolicitanteVoluntariado.hashCode ^
      descripcionSolicitanteVoluntariado.hashCode ^
      estadoSolicitanteVoluntariado.hashCode ^
      fechaSolicitanteVoluntariado.hashCode;
}
