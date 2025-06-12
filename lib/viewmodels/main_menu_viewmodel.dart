import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// ViewModel para manejar la lógica del menú principal
class MainMenuViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  MainMenuViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _initializeUser();
  }
  /// Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get welcomeMessage => _currentUser?.name ?? 'Usuario';
  bool get isAuthenticated => _currentUser != null;

  /// Inicializa el usuario actual
  Future<void> _initializeUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar información del usuario');
    }
  }

  /// Cierra la sesión
  Future<bool> signOut() async {
    _setLoading(true);
    
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _clearError();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error al cerrar sesión');
      _setLoading(false);
      return false;
    }
  }

  /// Navega a la sección de donaciones
  void navigateToDonaciones() {
    // TODO: Implementar navegación a donaciones
    _showFeatureNotImplemented('Gestión de Donaciones');
  }

  /// Navega a la sección de adopciones
  void navigateToAdopciones() {
    // TODO: Implementar navegación a adopciones
    _showFeatureNotImplemented('Gestión de Adopciones');
  }

  /// Navega a la sección de campañas
  void navigateToCampanas() {
    // TODO: Implementar navegación a campañas
    _showFeatureNotImplemented('Gestión de Campañas');
  }

  /// Navega a la sección de animales
  void navigateToAnimales() {
    // TODO: Implementar navegación a animales
    _showFeatureNotImplemented('Gestión de Animales');
  }

  /// Muestra mensaje de funcionalidad no implementada
  void _showFeatureNotImplemented(String featureName) {
    _setError('$featureName estará disponible próximamente');
    
    // Limpiar el error después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      _clearError();
    });
  }

  /// Actualiza el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establece un mensaje de error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpia el error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Limpia el error manualmente
  void clearError() {
    _clearError();
  }
}
