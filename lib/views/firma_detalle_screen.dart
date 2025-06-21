import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/firma_model.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/firma_viewmodel.dart';

class FirmaDetalleScreen extends StatefulWidget {
  final FirmaModel firma;
  final int? firmaIndex;

  const FirmaDetalleScreen({
    super.key, 
    required this.firma,
    this.firmaIndex,
  });

  @override
  State<FirmaDetalleScreen> createState() => _FirmaDetalleScreenState();
}

class _FirmaDetalleScreenState extends State<FirmaDetalleScreen> {
  late FirmaModel _firma;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firma = widget.firma;
    _loadFirmaIfNeeded();
  }

  Future<void> _loadFirmaIfNeeded() async {
    // Si ya tiene la imagen cargada o no hay índice de firma, no hacer nada
    if (_firma.imagenFirma != null || widget.firmaIndex == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = context.read<FirmaViewModel>();
      await viewModel.loadFirmaImage(widget.firmaIndex!);
      
      if (mounted) {
        setState(() {
          _firma = viewModel.firmas[widget.firmaIndex!];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = firmaErrorCargar;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          firmaDetalleTitulo,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con ancho fijo basado en el ancho de la pantalla
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // 90% del ancho de la pantalla
              child: Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _firma.nombreFirma,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(firmaDniLabel, _firma.dniFirma.toString(), context),
                    const SizedBox(height: 12),
                    _buildInfoRow(firmaMotivoLabel, _firma.motivoFirma, context),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      firmaFechaRegistroLabel,
                      _firma.fechaRegistro.toLocal().toString().split(' ')[0],
                      context,
                    ),
                  ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sección de la imagen de la firma
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 16.0),
                  child: Text(
                    firmaLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(grey900, Colors.transparent, 0.9) ?? grey900,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFirmaImage(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmaImage() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                cargandoFirmas,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: errorRed, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: errorRed),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFirmaIfNeeded,
            icon: const Icon(Icons.refresh),
            label: const Text(botonReintentar),
          ),
        ],
      );
    }

    if (_firma.imagenFirma == null || _firma.imagenFirma!.isEmpty) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, size: 48, color: grey500),
          SizedBox(height: 8),
          Text(imagenNoDisponible),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _firma.imagenFirma!,
        width: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Error al cargar la imagen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}
