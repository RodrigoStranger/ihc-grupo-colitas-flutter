import 'package:flutter/material.dart';
import 'package:ihc_grupo_colitas_flutter/models/donacion_model.dart';
import 'package:provider/provider.dart';

import '../core/colors.dart';
import '../viewmodels/donacion_viewmodel.dart';
import 'donacion_detalle_screen.dart';

class DonacionesScreen extends StatefulWidget {
  const DonacionesScreen({super.key});

  @override
  State<DonacionesScreen> createState() => _DonacionesScreenState();
}

class _DonacionesScreenState extends State<DonacionesScreen> {
  final ScrollController _scrollController = ScrollController();
  String _filtroEstado = 'Todos'; // Filtro seleccionado
  final List<String> _opcionesFiltro = ['Todos', 'Pendiente', 'Aceptado', 'Rechazado'];

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
    
    // Mapear "Aceptado" del filtro UI a "Aprobado" del backend
    String estadoBackend = _filtroEstado;
    if (_filtroEstado == 'Aceptado') {
      estadoBackend = 'Aprobado';
    }
    
    return solicitudes.where((solicitud) => 
      solicitud.estadoSolicitanteDonacion.toLowerCase() == estadoBackend.toLowerCase()).toList();
  }

  Widget _buildSolicitudCard(BuildContext context, Donacion solicitud) {
    Color statusColor;
    IconData statusIcon;

    switch (solicitud.estadoSolicitanteDonacion.toLowerCase()) {
      case 'pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'aprobado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rechazado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completado':
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSolicitudDetails(context, solicitud),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      solicitud.nombreSolicitanteDonacion,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    avatar: Icon(statusIcon, size: 16, color: statusColor),
                    label: Text(
                      solicitud.estadoSolicitanteDonacion,
                      style: TextStyle(color: statusColor),
                    ),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                solicitud.descripcionSolicitanteDonacion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: grey600),
                  const SizedBox(width: 8),
                  Text(solicitud.numero1SolicitanteDonacion),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: grey600),
                  const SizedBox(width: 8),
                  Text(solicitud.fechaSolicitanteDonacion.toString()),
                ],
              ),
              if (solicitud.estadoSolicitanteDonacion.toLowerCase() ==
                  'pendiente')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () =>
                            _cambiarEstado(context, solicitud, 'Rechazado'),
                        child: const Text(
                          'Rechazar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () =>
                            _cambiarEstado(context, solicitud, 'Aprobado'),
                        child: const Text('Aprobar'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSolicitudDetails(
    BuildContext context,
    Donacion solicitud,
  ) async {
    final viewModel = context.read<DonacionViewModel>();
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonacionDetalleScreen(solicitud: solicitud),
      ),
    );
    // Actualizar lista después de regresar
    if (mounted) {
      viewModel.fetchSolicitudes();
    }
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
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Solicitud ${nuevoEstado.toLowerCase()} con éxito'),
          backgroundColor: nuevoEstado == 'Aprobado'
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
