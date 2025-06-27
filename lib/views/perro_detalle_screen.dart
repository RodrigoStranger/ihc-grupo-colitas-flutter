import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/perro_model.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../widgets/adopcion_confirmation_dialog.dart';

class PerroDetalleScreen extends StatefulWidget {
  final PerroModel perro;
  final int? perroIndex;

  const PerroDetalleScreen({
    super.key, 
    required this.perro,
    this.perroIndex,
  });

  @override
  State<PerroDetalleScreen> createState() => _PerroDetalleScreenState();
}

class _PerroDetalleScreenState extends State<PerroDetalleScreen> {
  late PerroModel _perro;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _perro = widget.perro;
    _loadPerroImageIfNeeded();
  }

  Future<void> _loadPerroImageIfNeeded() async {
    // Si ya tiene la imagen cargada o no hay índice de perro, no hacer nada
    if (_perro.fotoPerro != null && _perro.fotoPerro!.startsWith('http') || widget.perroIndex == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = context.read<PerroViewModel>();
      await viewModel.loadPerroImage(widget.perroIndex!);
      
      if (mounted) {
        setState(() {
          _perro = viewModel.perros[widget.perroIndex!];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar imagen del perro';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _marcarComoAdoptado() async {
    // Mostrar diálogo de confirmación usando el widget modularizado
    final confirmar = await AdopcionConfirmationDialog.show(context, _perro.nombrePerro);

    if (confirmar == true) {
      await _actualizarEstadoPerro();
    }
  }

  Future<void> _actualizarEstadoPerro() async {
    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      final viewModel = context.read<PerroViewModel>();
      
      // Crear una copia del perro con estado adoptado
      final perroActualizado = _perro.copyWith(
        estadoPerro: estadoAdoptado,
      );

      // Actualizar en la base de datos
      final exito = await viewModel.updatePerro(_perro.id!, perroActualizado);

      if (exito) {
        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_perro.nombrePerro} ha sido marcado como adoptado'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Actualizar el estado local
          setState(() {
            _perro = perroActualizado;
          });
        }
      } else {
        _mostrarError(viewModel.error ?? 'Error al actualizar el estado del perro');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: grey700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textDark,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip() {
    Color colorFondo;
    Color colorTexto;
    IconData icono;

    switch (_perro.estadoPerro) {
      case estadoDisponible:
        colorFondo = const Color.fromRGBO(76, 175, 80, 0.1);
        colorTexto = Colors.green[700]!;
        icono = Icons.pets;
        break;
      case estadoAdoptado:
        colorFondo = const Color.fromRGBO(33, 150, 243, 0.1);
        colorTexto = Colors.blue[700]!;
        icono = Icons.favorite;
        break;
      case estadoTratamiento:
        colorFondo = const Color.fromRGBO(255, 152, 0, 0.1);
        colorTexto = Colors.orange[700]!;
        icono = Icons.medical_services;
        break;
      default:
        colorFondo = grey200;
        colorTexto = grey700;
        icono = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorTexto.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 16,
            color: colorTexto,
          ),
          const SizedBox(width: 6),
          Text(
            _perro.estadoPerro,
            style: TextStyle(
              color: colorTexto,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _perro.nombrePerro,
          style: const TextStyle(
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
            // Tarjeta principal con información del perro
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
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
                      // Nombre y estado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _perro.nombrePerro,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                            ),
                          ),
                          _buildEstadoChip(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Información básica
                      _buildInfoRow('Edad:', '${_perro.edadPerro} años', context),
                      const SizedBox(height: 12),
                      _buildInfoRow('Sexo:', _perro.sexoPerro, context),
                      const SizedBox(height: 12),
                      _buildInfoRow('Raza:', _perro.razaPerro, context),
                      const SizedBox(height: 12),
                      _buildInfoRow('Pelaje:', _perro.pelajePerro, context),
                      const SizedBox(height: 12),
                      _buildInfoRow('Actividad:', _perro.actividadPerro, context),
                      const SizedBox(height: 12),
                      _buildInfoRow('Estatura:', _perro.estaturaPerro, context),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Ingreso:',
                        _perro.ingresoPerro.isNotEmpty 
                            ? _perro.ingresoPerro.split('T')[0] // Extraer solo la fecha de la string ISO
                            : 'No disponible',
                        context,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de descripción
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: grey900.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _perro.descripcionPerro,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textDark,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de la imagen del perro
            if (_perro.fotoPerro != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Foto del Perro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: grey900.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: errorRed,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: errorRed),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _perro.fotoPerro!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: grey500,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No se pudo cargar la imagen',
                                              style: TextStyle(color: grey600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Botón para marcar como adoptado (solo si está disponible)
            if (_perro.estadoPerro == estadoDisponible) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _marcarComoAdoptado,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.favorite),
                  label: Text(
                    _isUpdating ? 'Actualizando...' : 'Marcar como Adoptado',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
