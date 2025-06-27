import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../models/perro_model.dart';
import 'perro_detalle_screen.dart';

class PerrosScreen extends StatefulWidget {
  const PerrosScreen({super.key});

  @override
  State<PerrosScreen> createState() => _PerrosScreenState();
}

class _PerrosScreenState extends State<PerrosScreen> {
  @override
  void initState() {
    super.initState();
    // Usar el ViewModel global y cargar datos si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<PerroViewModel>();
        if (viewModel.perros.isEmpty) {
          viewModel.getAllPerros();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          menuAnimalesTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
      ),
      body: Consumer<PerroViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.perros.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      perrosCargando,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.error != null && viewModel.perros.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${viewModel.error}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.getAllPerros(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.perros.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    perrosNoRegistrados,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.getAllPerros(),
              color: accentBlue,
              backgroundColor: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.perros.length,
                itemBuilder: (context, index) {
                  final perro = viewModel.perros[index];
                  return _buildPerroCard(perro);
                },
              ),
            );
          },
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capturar el contexto y ViewModel antes del gap asíncrono
          final navigator = Navigator.of(context);
          final viewModel = Provider.of<PerroViewModel>(context, listen: false);
          
          // Navegar a agregar perro y esperar el resultado
          final resultado = await navigator.pushNamed('/agregar-perro');
          
          // Si se agregó un perro exitosamente, el ViewModel ya recargó la lista
          // Pero podemos hacer una validación adicional si es necesario
          if (resultado == true && mounted) {
            // Solo recargar si la lista está vacía por alguna razón
            if (viewModel.perros.isEmpty) {
              await viewModel.getAllPerros();
            }
          }
        },
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPerroCard(PerroModel perro) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showPerroDetails(perro),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con nombre y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        perro.nombrePerro,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                    _buildEstadoChip(perro.estadoPerro),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Información básica
                Row(
                  children: [
                    Icon(
                      perro.sexoPerro == 'Macho' ? Icons.male : Icons.female,
                      size: 16,
                      color: perro.sexoPerro == 'Macho' ? accentBlue : Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${perro.sexoPerro} • ${perro.edadPerro} años',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Raza
                Text(
                  perro.razaPerro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textMedium,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Descripción (truncada)
                Text(
                  perro.descripcionPerro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textMedium,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Información adicional
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      size: 14,
                      color: textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      perro.pelajePerro,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.directions_run,
                      size: 14,
                      color: textMedium,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        perro.actividadPerro,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Fecha de ingreso
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ingreso: ${_formatDate(perro.ingresoPerro)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    IconData icon;
    
    switch (estado.toLowerCase()) {
      case 'disponible':
        color = Colors.green;
        icon = Icons.pets;
        break;
      case 'adoptado':
        color = Colors.orange;
        icon = Icons.home;
        break;
      case 'en proceso':
        color = accentBlue;
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'No disponible';
    try {
      // Si es una fecha ISO, extraer solo la parte de la fecha
      if (dateString.contains('T')) {
        return dateString.split('T')[0];
      }
      return dateString;
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _showPerroDetails(PerroModel perro) {
    final viewModel = context.read<PerroViewModel>();
    // Encontrar el índice del perro para pasarlo a la pantalla de detalle
    final index = viewModel.perros.indexOf(perro);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PerroDetalleScreen(
          perro: perro,
          perroIndex: index >= 0 ? index : null,
        ),
      ),
    ).then((_) {
      // Refrescar la lista al volver de la pantalla de detalle
      // en caso de que se haya actualizado el estado del perro
      if (mounted) {
        viewModel.getAllPerros();
      }
    });
  }
}
