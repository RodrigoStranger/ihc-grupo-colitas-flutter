class FirmaModel {
  final int dniFirma;
  final String nombreFirma;
  final String motivoFirma;
  final DateTime fechaRegistro;
  final String? imagenFirma;

  FirmaModel({
    required this.dniFirma,
    required this.nombreFirma,
    required this.motivoFirma,
    required this.fechaRegistro,
    this.imagenFirma,
  });

  factory FirmaModel.fromMap(Map<String, dynamic> map) {
    return FirmaModel(
      dniFirma: map['DniFirma'] as int,
      nombreFirma: map['NombreFirma'] as String,
      motivoFirma: map['MotivoFirma'] as String,
      fechaRegistro: DateTime.parse(map['FechaRegistro'] as String),
      imagenFirma: map['ImagenFirma'] as String?,
    );
  }
}
