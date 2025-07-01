import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/solicitud_adopcion_viewmodel.dart';
import '../models/solicitud_adopcion_model.dart';
import '../widgets/base_confirmation_dialog.dart';

class SolicitudesAdopcionScreen extends StatefulWidget {
  const SolicitudesAdopcionScreen({super.key});

  @override
  State<SolicitudesAdopcionScreen> createState() => _SolicitudesAdopcionScreenState();
}

class _SolicitudesAdopcionScreenState extends State<SolicitudesAdopcionScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _initialLoadCompleted = false;
  SolicitudAdopcionViewModel? _viewModel;
  String _filtroEstado = 'Todos'; // Filtro seleccionado
  final List<String> _opcionesFiltro = ['Todos', 'Pendiente', 'Aceptado', 'Rechazado'];
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_viewModel != null &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_viewModel!.isLoading && !_viewModel!.isLoadingMore) {
        _viewModel!.loadMoreSolicitudes();
      }
    }
  }

  // Método para contactar por WhatsApp
  Future<void> _contactarWhatsApp(SolicitudAdopcionModel solicitud) async {
    final numero1 = solicitud.numero1Solicitante;
    final numero2 = solicitud.numero2Solicitante;

    // Si solo hay un número, usar ese directamente
    if (numero2 == null || numero2.isEmpty) {
      await _abrirWhatsApp(numero1, solicitud.nombreSolicitante);
      return;
    }

    // Si hay dos números, mostrar opciones
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(seleccionarTelefono),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: accentBlue),
              title: Text('Teléfono 1: $numero1'),
              onTap: () {
                Navigator.pop(context);
                _abrirWhatsApp(numero1, solicitud.nombreSolicitante);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: accentBlue),
              title: Text('Teléfono 2: $numero2'),
              onTap: () {
                Navigator.pop(context);
                _abrirWhatsApp(numero2, solicitud.nombreSolicitante);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(botonCancelar),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp(String telefono, String nombre) async {
    // Limpiar el número: quitar espacios, guiones, paréntesis
    String numeroLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si no empieza con +, agregar código de país de Perú
    if (!numeroLimpio.startsWith('+')) {
      if (numeroLimpio.startsWith('9')) {
        numeroLimpio = '+51$numeroLimpio';
      } else if (numeroLimpio.length == 9) {
        numeroLimpio = '+51$numeroLimpio';
      } else {
        numeroLimpio = '+51$numeroLimpio';
      }
    }
    
    final mensaje = Uri.encodeComponent(
      'Hola $nombre, te contactamos desde Grupo Colitas Arequipa sobre tu solicitud de adopción.'
    );
    final url = 'https://wa.me/$numeroLimpio?text=$mensaje';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir WhatsApp para el número: $numeroLimpio'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contactar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Confirmar aceptar solicitud
  Future<void> _confirmarAceptarSolicitud(SolicitudAdopcionModel solicitud) async {
    final confirm = await BaseConfirmationDialog.show(
      context,
      title: 'Aceptar Solicitud',
      titleIcon: Icons.check_circle,
      message: '¿Estás seguro de que quieres aceptar la solicitud de adopción de ${solicitud.nombreSolicitante} para el perro ${solicitud.nombrePerro ?? 'sin nombre'}?',
      warningMessage: 'Esta acción marcará al perro como adoptado y cambiará el estado de la solicitud.',
      confirmText: 'Aceptar Solicitud',
      confirmColor: Colors.green,
    );

    if (confirm == true && mounted) {
      final viewModel = context.read<SolicitudAdopcionViewModel>();
      final success = await viewModel.aceptarSolicitud(solicitud.id!, solicitud.idPerro);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(solicitudAceptadaExito),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Confirmar rechazar solicitud
  Future<void> _confirmarRechazarSolicitud(SolicitudAdopcionModel solicitud) async {
    final confirm = await BaseConfirmationDialog.show(
      context,
      title: 'Rechazar Solicitud',
      titleIcon: Icons.cancel,
      message: '¿Estás seguro de que quieres rechazar la solicitud de adopción de ${solicitud.nombreSolicitante} para el perro ${solicitud.nombrePerro ?? 'sin nombre'}?',
      warningMessage: 'Esta acción cambiará el estado de la solicitud a rechazado.',
      confirmText: 'Rechazar Solicitud',
      confirmColor: Colors.red,
      cancelColor: accentBlue,
    );

    if (confirm == true && mounted) {
      final viewModel = context.read<SolicitudAdopcionViewModel>();
      final success = await viewModel.rechazarSolicitud(solicitud.id!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(solicitudRechazadaExito),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'aceptado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          solicitudesAdopcionTitulo,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _filtroEstado = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _opcionesFiltro.map((String opcion) {
                return PopupMenuItem<String>(
                  value: opcion,
                  child: Row(
                    children: [
                      Icon(
                        _filtroEstado == opcion ? Icons.check : Icons.circle_outlined,
                        color: _filtroEstado == opcion ? accentBlue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(opcion),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chip indicador del filtro activo
          if (_filtroEstado != 'Todos')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$filtrandoLabel$_filtroEstado',
                    style: TextStyle(
                      color: accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroEstado = 'Todos';
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          // Lista de solicitudes
          Expanded(
            child: Consumer<SolicitudAdopcionViewModel>(
        builder: (context, viewModel, _) {
            // Asignar el viewModel para uso en _onScroll
            _viewModel = viewModel;
            
            // Cargar las solicitudes solo una vez al inicio con optimización
            if (!viewModel.isLoading && viewModel.solicitudes.isEmpty && !_initialLoadCompleted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Usar el método optimizado para la primera carga
                  viewModel.initializeWithOptimizedImageLoading().then((_) {
                    if (mounted) {
                      setState(() {
                        _initialLoadCompleted = true;
                      });
                    }
                  });
                }
              });
            }

            // Mostrar mensaje de procesamiento si hay alguna operación en curso
            if (viewModel.processingMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.processingMessage!),
                    backgroundColor: accentBlue,
                  ),
                );
              });
            }

            if (viewModel.isLoading && viewModel.solicitudes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      solicitudesCargando,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            if (viewModel.error != null && viewModel.solicitudes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$solicitudesErrorCargar ${viewModel.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.initializeWithOptimizedImageLoading(),
                      child: const Text(botonReintentar),
                    ),
                  ],
                ),
              );
            }
            
            final todasLasSolicitudes = viewModel.solicitudes;
            final solicitudes = _filtrarSolicitudes(todasLasSolicitudes);
            
            if (todasLasSolicitudes.isNotEmpty && solicitudes.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                color: accentBlue,
                backgroundColor: Colors.white,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$noHaySolicitudesFiltro $_filtroEstado'.toLowerCase(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cambiarFiltroHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            if (solicitudes.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                color: accentBlue,
                backgroundColor: Colors.white,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                      child: Text(
                        solicitudesNoRegistradas,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () => viewModel.refresh(),
              color: accentBlue,
              backgroundColor: Colors.white,
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: solicitudes.length + (viewModel.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= solicitudes.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentBlue,
                        ),
                      ),
                    );
                  }
                  
                  final solicitud = solicitudes[index];
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(grey900, Colors.transparent, 0.9) ?? grey900,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con foto del perro e información básica
                        Row(
                          children: [
                            // Foto del perro
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: lightBlue50,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildPerroImage(solicitud),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información básica
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$solicitudPerroLabel${solicitud.nombrePerro ?? 'Perro sin nombre'}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$solicitudNombreLabel${solicitud.nombreSolicitante}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        solicitudEstadoLabel,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getEstadoColor(solicitud.estadoSolicitante),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          solicitud.estadoSolicitante,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Información adicional
                        Text(
                          '$solicitudTelefono1Label${solicitud.numero1Solicitante}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (solicitud.numero2Solicitante != null && solicitud.numero2Solicitante!.isNotEmpty) ...[
                          Text(
                            '$solicitudTelefono2Label${solicitud.numero2Solicitante}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '$solicitudFechaLabel${solicitud.fechaSolicitante}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: grey600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Descripción
                        if (solicitud.descripcionSolicitante.isNotEmpty) ...[
                          Text(
                            solicitudDescripcionLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            solicitud.descripcionSolicitante,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Botones de acción según el estado
                        if (solicitud.estadoSolicitante.toLowerCase().trim() == 'pendiente') ...[
                          // Solicitudes pendientes: 3 botones
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isProcessing 
                                    ? null 
                                    : () => _confirmarAceptarSolicitud(solicitud),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text(botonAceptarSolicitud),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isProcessing 
                                    ? null 
                                    : () => _confirmarRechazarSolicitud(solicitud),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text(botonRechazarSolicitud),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _contactarWhatsApp(solicitud),
                                icon: const Icon(Icons.message, size: 18),
                                label: const Text(botonContactarWhatsApp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                ),
                              ),
                            ],
                          ),
                        ] else if (solicitud.estadoSolicitante.toLowerCase().trim() == 'aceptado') ...[
                          // Solicitudes aceptadas: solo contactar + estado
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Solicitud Aceptada',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _contactarWhatsApp(solicitud),
                                icon: const Icon(Icons.message, size: 18),
                                label: const Text(botonContactarWhatsApp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                ),
                              ),
                            ],
                          ),
                        ] else if (solicitud.estadoSolicitante.toLowerCase().trim() == 'rechazado') ...[
                          // Solicitudes rechazadas: solo contactar + estado
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cancel, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Solicitud Rechazada',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _contactarWhatsApp(solicitud),
                                icon: const Icon(Icons.message, size: 18),
                                label: const Text(botonContactarWhatsApp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Estado desconocido: mostrar todos los botones por defecto
                          Column(
                            children: [
                              Text(
                                'Estado desconocido: "${solicitud.estadoSolicitante}"',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: viewModel.isProcessing 
                                        ? null 
                                        : () => _confirmarAceptarSolicitud(solicitud),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text(botonAceptarSolicitud),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: viewModel.isProcessing 
                                        ? null 
                                        : () => _confirmarRechazarSolicitud(solicitud),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text(botonRechazarSolicitud),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _contactarWhatsApp(solicitud),
                                    icon: const Icon(Icons.message, size: 18),
                                    label: const Text(botonContactarWhatsApp),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerroImage(SolicitudAdopcionModel solicitud) {
    if (solicitud.fotoPerro == null || solicitud.fotoPerro!.isEmpty) {
      return const Icon(
        Icons.pets,
        size: 40,
        color: blue500,
      );
    }

    if (solicitud.isLoadingImage) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: accentBlue,
          ),
        ),
      );
    }

    if (solicitud.errorLoadingImage != null) {
      return const Icon(
        Icons.error_outline,
        size: 30,
        color: Colors.red,
      );
    }

    if (solicitud.fotoPerro!.startsWith('http')) {
      return Image.network(
        solicitud.fotoPerro!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentBlue,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.error_outline,
            size: 30,
            color: Colors.red,
          );
        },
      );
    }

    return const Icon(
      Icons.pets,
      size: 40,
      color: blue500,
    );
  }

  // Función para filtrar solicitudes por estado
  List<SolicitudAdopcionModel> _filtrarSolicitudes(List<SolicitudAdopcionModel> solicitudes) {
    if (_filtroEstado == 'Todos') {
      return solicitudes;
    }
    return solicitudes.where((solicitud) => 
      solicitud.estadoSolicitante.toLowerCase() == _filtroEstado.toLowerCase()).toList();
  }
}
