import 'user_model.dart';

/// Estados posibles de la autenticación
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Modelo que representa el estado de autenticación
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
  });

  /// Estado inicial
  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        error = null,
        isLoading = false;

  /// Estado de carga
  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        error = null,
        isLoading = true;

  /// Estado autenticado
  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        error = null,
        isLoading = false;

  /// Estado no autenticado
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        error = null,
        isLoading = false;

  /// Estado de error
  const AuthState.error(this.error)
      : status = AuthStatus.error,
        user = null,
        isLoading = false;

  /// Crea una copia del estado con algunos campos modificados
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: $user, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.error == error &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        user.hashCode ^
        error.hashCode ^
        isLoading.hashCode;
  }
}
