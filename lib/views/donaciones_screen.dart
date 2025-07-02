import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ihc_grupo_colitas_flutter/models/donacion_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../core/colors.dart';
import '../viewmodels/donacion_viewmodel.dart';

class DonacionesScreen extends StatefulWidget {
  const DonacionesScreen({super.key});

  @override
  State<DonacionesScreen> createState() => _DonacionesScreenState();
}

class _DonacionesScreenState extends State<DonacionesScreen> {
  final ScrollController _scrollController = ScrollController();
  String _filtroEstado = 'Todos'; // Filtro seleccionado
  final List<String> _opcionesFiltro = ['Todos', 'Pendiente', 'Concluido', 'No concluido'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DonacionViewModel>().fetchSolicitudes();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final viewModel = context.read<DonacionViewModel>();
      if (!viewModel.isLoading && !viewModel.isLoadingMore) {
        viewModel.loadMoreSolicitudes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        title: const Text(
          'Solicitudes de Donación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: accentBlue,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    'Filtrando: $_filtroEstado',
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
          // Lista de donaciones
          Expanded(
            child: Consumer<DonacionViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.solicitudes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: accentBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando solicitudes...',
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
                  Text('Error: ${viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.fetchSolicitudes,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.solicitudes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No hay solicitudes pendientes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final todasLasSolicitudes = viewModel.solicitudes;
          final solicitudes = _filtrarSolicitudes(todasLasSolicitudes);

          if (todasLasSolicitudes.isNotEmpty && solicitudes.isEmpty) {
            return RefreshIndicator(
              onRefresh: viewModel.fetchSolicitudes,
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
                          'No hay solicitudes con filtro: $_filtroEstado',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cambia el filtro para ver más resultados',
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

          return RefreshIndicator(
            onRefresh: viewModel.fetchSolicitudes,
            color: accentBlue,
            backgroundColor: Colors.white,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount:
                  solicitudes.length +
                  (viewModel.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= solicitudes.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: accentBlue),
                    ),
                  );
                }
                return _buildSolicitudCard(
                  context,
                  solicitudes[index],
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

  // Función para filtrar solicitudes por estado
  List<Donacion> _filtrarSolicitudes(List<Donacion> solicitudes) {
    if (_filtroEstado == 'Todos') {
      return solicitudes;
    }
    
    // Mapear estados del filtro UI a estados del backend
    String estadoBackend = _filtroEstado;
    if (_filtroEstado == 'Concluido') {
      estadoBackend = 'Concluido';
    } else if (_filtroEstado == 'No concluido') {
      estadoBackend = 'No Concluido';
    }
    
    return solicitudes.where((solicitud) => 
      solicitud.estadoSolicitanteDonacion.toLowerCase() == estadoBackend.toLowerCase()).toList();
  }

  // Método para contactar por WhatsApp
  Future<void> _contactarWhatsApp(Donacion solicitud) async {
    final numero1 = solicitud.numero1SolicitanteDonacion;
    final numero2 = solicitud.numero2SolicitanteDonacion;

    // Si solo hay un número, usar ese directamente
    if (numero2 == null || numero2.isEmpty) {
      await _abrirWhatsApp(numero1, solicitud.nombreSolicitanteDonacion);
      return;
    }

    // Si hay dos números, mostrar opciones
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.phone,
              color: accentBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Seleccionar teléfono',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.phone, color: accentBlue, size: 20),
                ),
                title: Text(
                  'Teléfono 1',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  numero1,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _abrirWhatsApp(numero1, solicitud.nombreSolicitanteDonacion);
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.phone, color: accentBlue, size: 20),
                ),
                title: Text(
                  'Teléfono 2',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  numero2,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _abrirWhatsApp(numero2, solicitud.nombreSolicitanteDonacion);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp(String telefono, String nombre) async {
    try {
      // Limpiar el número: quitar espacios, guiones, paréntesis
      String numeroLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Si no empieza con +, agregar código de país de Perú
      if (!numeroLimpio.startsWith('+')) {
        if (numeroLimpio.startsWith('9') && numeroLimpio.length == 9) {
          numeroLimpio = '+51$numeroLimpio';
        } else if (numeroLimpio.length == 9) {
          numeroLimpio = '+51$numeroLimpio';
        } else if (numeroLimpio.length == 8) {
          numeroLimpio = '+519$numeroLimpio';
        } else {
          numeroLimpio = '+51$numeroLimpio';
        }
      }
      
      final mensaje = Uri.encodeComponent(
        'Hola $nombre, te contactamos desde Grupo Colitas Arequipa sobre tu solicitud de donación.'
      );
      
      // SIEMPRE usar el número CON +51 para wa.me
      // Solo quitar el + para esquemas nativos como whatsapp://
      
      // Intentar método directo primero CON +51
      final urlDirecta = 'https://wa.me/$numeroLimpio?text=$mensaje';
      
      try {
        final uri = Uri.parse(urlDirecta);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          return;
        }
      } catch (e) {
        // Continuar con el siguiente método
      }
      
      // Si falla, intentar con esquema nativo SIN +
      final numeroSinMas = numeroLimpio.replaceAll('+', '');
      final urlNativa = 'whatsapp://send?phone=$numeroSinMas&text=$mensaje';
      
      try {
        final uri = Uri.parse(urlNativa);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          return;
        }
      } catch (e) {
        // Continuar con el siguiente método
      }
      
      // Último intento: usar launchUrl con diferentes modos CON +51
      final urlFinal = 'https://wa.me/$numeroLimpio?text=$mensaje';
      
      // Intentar con diferentes modos de lanzamiento
      final modes = [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
        LaunchMode.externalNonBrowserApplication,
      ];
      
      for (final mode in modes) {
        try {
          final uri = Uri.parse(urlFinal);
          final launched = await launchUrl(uri, mode: mode);
          
          if (launched) {
            return;
          }
        } catch (e) {
          // Continuar con el siguiente modo
        }
      }
      
      throw 'No se pudo abrir WhatsApp. Número: $numeroLimpio';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contactar por WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Copiar número',
              textColor: Colors.white,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: telefono));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Número copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  // Función para mostrar modal de confirmación para concluir donación
  Future<void> _mostrarConfirmacionConcluir(BuildContext context, Donacion solicitud) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Confirmar Conclusión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de que deseas marcar esta donación como concluida?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción marcará la donación como exitosamente completada.',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstado(context, solicitud, 'Concluido');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Marcar como Concluido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Función para mostrar modal de confirmación para no concluir donación
  Future<void> _mostrarConfirmacionNoConcluir(BuildContext context, Donacion solicitud) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Confirmar No Conclusión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de que deseas marcar esta donación como no concluida?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción marcará la donación como no completada o fallida.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstado(context, solicitud, 'No Concluido');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Marcar como No Concluido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
      case 'concluido':
        return Colors.green;
      case 'rechazado':
      case 'no concluido':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatearFecha(DateTime fecha) {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      return formatter.format(fecha);
    } catch (e) {
      // Si hay error al formatear la fecha, devolver la fecha original
      return fecha.toString();
    }
  }

  Widget _buildSolicitudCard(BuildContext context, Donacion solicitud) {
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
          // Header con información básica
          Row(
            children: [
              // Icono de donación
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: lightBlue50,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 40,
                    color: accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información básica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donación de: ${solicitud.nombreSolicitanteDonacion}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solicitante: ${solicitud.nombreSolicitanteDonacion}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Estado: ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(solicitud.estadoSolicitanteDonacion),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            solicitud.estadoSolicitanteDonacion,
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
            'Teléfono 1: ${solicitud.numero1SolicitanteDonacion}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (solicitud.numero2SolicitanteDonacion != null && solicitud.numero2SolicitanteDonacion!.isNotEmpty) ...[
            Text(
              'Teléfono 2: ${solicitud.numero2SolicitanteDonacion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Fecha: ${_formatearFecha(solicitud.fechaSolicitanteDonacion)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: grey600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Descripción
          if (solicitud.descripcionSolicitanteDonacion.isNotEmpty) ...[
            Text(
              'Descripción de la Donación:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solicitud.descripcionSolicitanteDonacion,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          
          // Botones de acción según el estado
          if (solicitud.estadoSolicitanteDonacion.toLowerCase().trim() == 'pendiente') ...[
            // Solicitudes pendientes: 3 botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _mostrarConfirmacionConcluir(context, solicitud),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Concluido'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _mostrarConfirmacionNoConcluir(context, solicitud),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('No Concluido'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _contactarWhatsApp(solicitud),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Contactar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ),
          ] else if (solicitud.estadoSolicitanteDonacion.toLowerCase().trim() == 'concluido') ...[
            // Solicitudes concluidas: solo contactar + estado
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
                          'Donación Concluida',
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
                  label: const Text('Contactar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ),
              ],
            ),
          ] else if (solicitud.estadoSolicitanteDonacion.toLowerCase().trim() == 'no concluido') ...[
            // Solicitudes no concluidas: solo contactar + estado
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
                          'Donación No Concluida',
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
                  label: const Text('Contactar'),
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
                  'Estado desconocido: "${solicitud.estadoSolicitanteDonacion}"',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _mostrarConfirmacionConcluir(context, solicitud),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Concluido'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _mostrarConfirmacionNoConcluir(context, solicitud),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('No Concluido'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _contactarWhatsApp(solicitud),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Contactar'),
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
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    Donacion solicitud,
    String nuevoEstado,
  ) async {
    final viewModel = context.read<DonacionViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await viewModel.cambiarEstadoSolicitud(
        solicitud.idSolicitanteDonacion!,
        nuevoEstado,
      );
      if (!mounted) return;
      
      String mensaje = nuevoEstado == 'Concluido' 
          ? 'Donación marcada como concluida con éxito'
          : 'Donación marcada como no concluida con éxito';
          
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: nuevoEstado == 'Concluido'
              ? Colors.green
              : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
