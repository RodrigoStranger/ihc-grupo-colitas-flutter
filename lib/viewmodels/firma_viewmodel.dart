import 'package:flutter/material.dart';
import '../models/firma_model.dart';
import '../repositories/firma_repository.dart';

class FirmaViewModel extends ChangeNotifier {
  final FirmaRepository _repository = FirmaRepository();

  List<FirmaModel> _firmas = [];
  List<FirmaModel> get firmas => _firmas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchFirmas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _firmas = await _repository.getFirmas();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}