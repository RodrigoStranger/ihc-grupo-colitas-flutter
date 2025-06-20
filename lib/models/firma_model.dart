class FirmaModel {
  final int dniFirma;
  final String nombreFirma;
  final String motivoFirma;
  final DateTime fechaRegistro;
  final String? imagenFirma;
  final bool isLoadingImage;
  final String? errorLoadingImage;

  FirmaModel({
    required this.dniFirma,
    required this.nombreFirma,
    required this.motivoFirma,
    required this.fechaRegistro,
    this.imagenFirma,
    this.isLoadingImage = false,
    this.errorLoadingImage,
  });

  factory FirmaModel.fromMap(Map<String, dynamic> map) {
    return FirmaModel(
      dniFirma: map['DniFirma'] as int,
      nombreFirma: map['NombreFirma'] as String,
      motivoFirma: map['MotivoFirma'] as String,
      fechaRegistro: DateTime.parse(map['FechaRegistro'] as String),
      imagenFirma: map['ImagenFirma'] as String?,
      isLoadingImage: false,
    );
  }

  FirmaModel copyWith({
    int? dniFirma,
    String? nombreFirma,
    String? motivoFirma,
    DateTime? fechaRegistro,
    String? imagenFirma,
    bool? isLoadingImage,
    String? errorLoadingImage,
  }) {
    return FirmaModel(
      dniFirma: dniFirma ?? this.dniFirma,
      nombreFirma: nombreFirma ?? this.nombreFirma,
      motivoFirma: motivoFirma ?? this.motivoFirma,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      imagenFirma: imagenFirma ?? this.imagenFirma,
      isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      errorLoadingImage: errorLoadingImage ?? this.errorLoadingImage,
    );
  }
}
