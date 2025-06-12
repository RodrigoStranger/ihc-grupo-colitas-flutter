/// Modelo que representa un usuario en el sistema
class UserModel {
  final String id;
  final String email;
  final String? name;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
    this.metadata,
  });

  /// Crea un UserModel desde un objeto User de Supabase
  factory UserModel.fromSupabaseUser(dynamic user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'],
      createdAt: user.createdAt != null ? DateTime.parse(user.createdAt) : null,
      metadata: user.userMetadata,
    );
  }

  /// Convierte el modelo a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Crea una copia del modelo con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode;
  }
}
