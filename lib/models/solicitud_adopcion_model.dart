class SolicitudAdopcionModel {
  final String? id;
  final String nombreSolicitante;
  final String numero1Solicitante;
  final String? numero2Solicitante;
  final String descripcionSolicitante;
  final String estadoSolicitante;
  final String fechaSolicitante;
  final String idPerro;
  final String? nombrePerro; // Para mostrar el nombre del perro en la UI
  final String? fotoPerro; // Para mostrar la foto del perro en la UI
  
  // Estados para la UI
  final bool isLoadingImage;
  final String? errorLoadingImage;

  SolicitudAdopcionModel({
    this.id,
    required this.nombreSolicitante,
    required this.numero1Solicitante,
    this.numero2Solicitante,
    required this.descripcionSolicitante,
    required this.estadoSolicitante,
    required this.fechaSolicitante,
    required this.idPerro,
    this.nombrePerro,
    this.fotoPerro,
    this.isLoadingImage = false,
    this.errorLoadingImage,
  });

  factory SolicitudAdopcionModel.fromMap(Map<String, dynamic> map) {
    return SolicitudAdopcionModel(
      id: map['IdSolicitanteAdopcion']?.toString(),
      nombreSolicitante: map['NombreSolicitanteAdopcion'] ?? '',
      numero1Solicitante: map['Numero1SolicitanteAdopcion'] ?? '',
      numero2Solicitante: map['Numero2SolicitanteAdopcion'],
      descripcionSolicitante: map['DescripcionSolicitanteAdopcion'] ?? '',
      estadoSolicitante: map['EstadoSolicitanteAdopcion'] ?? '',
      fechaSolicitante: map['FechaSolicitanteAdopcion'] ?? '',
      idPerro: map['IdPerro']?.toString() ?? '',
      nombrePerro: map['NombrePerro'],
      fotoPerro: map['FotoPerro'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'IdSolicitanteAdopcion': int.tryParse(id!),
      'NombreSolicitanteAdopcion': nombreSolicitante,
      'Numero1SolicitanteAdopcion': numero1Solicitante,
      if (numero2Solicitante != null) 'Numero2SolicitanteAdopcion': numero2Solicitante,
      'DescripcionSolicitanteAdopcion': descripcionSolicitante,
      'EstadoSolicitanteAdopcion': estadoSolicitante,
      'FechaSolicitanteAdopcion': fechaSolicitante,
      'IdPerro': int.tryParse(idPerro),
    };
  }

  SolicitudAdopcionModel copyWith({
    String? id,
    String? nombreSolicitante,
    String? numero1Solicitante,
    String? numero2Solicitante,
    String? descripcionSolicitante,
    String? estadoSolicitante,
    String? fechaSolicitante,
    String? idPerro,
    String? nombrePerro,
    String? fotoPerro,
    bool? isLoadingImage,
    String? errorLoadingImage,
  }) {
    return SolicitudAdopcionModel(
      id: id ?? this.id,
      nombreSolicitante: nombreSolicitante ?? this.nombreSolicitante,
      numero1Solicitante: numero1Solicitante ?? this.numero1Solicitante,
      numero2Solicitante: numero2Solicitante ?? this.numero2Solicitante,
      descripcionSolicitante: descripcionSolicitante ?? this.descripcionSolicitante,
      estadoSolicitante: estadoSolicitante ?? this.estadoSolicitante,
      fechaSolicitante: fechaSolicitante ?? this.fechaSolicitante,
      idPerro: idPerro ?? this.idPerro,
      nombrePerro: nombrePerro ?? this.nombrePerro,
      fotoPerro: fotoPerro ?? this.fotoPerro,
      isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      errorLoadingImage: errorLoadingImage ?? this.errorLoadingImage,
    );
  }

  @override
  String toString() {
    return 'SolicitudAdopcionModel('
        'id: $id, '
        'nombreSolicitante: $nombreSolicitante, '
        'numero1Solicitante: $numero1Solicitante, '
        'numero2Solicitante: $numero2Solicitante, '
        'descripcionSolicitante: $descripcionSolicitante, '
        'estadoSolicitante: $estadoSolicitante, '
        'fechaSolicitante: $fechaSolicitante, '
        'idPerro: $idPerro, '
        'nombrePerro: $nombrePerro, '
        'fotoPerro: $fotoPerro'
        ')';
  }
}
