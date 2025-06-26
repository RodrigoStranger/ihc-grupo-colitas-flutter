import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../models/perro_model.dart';

class PerrosScreen extends StatefulWidget {
  const PerrosScreen({super.key});

  @override
  State<PerrosScreen> createState() => _PerrosScreenState();
}

class _PerrosScreenState extends State<PerrosScreen> {
  late final PerroViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PerroViewModel();
    // Iniciar la carga inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.getAllPerros();
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: errorRed,
                    ),
                    const SizedBox(height: 16),
                        Text(
                          perrosErrorCargar,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            viewModel.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.getAllPerros(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(botonReintentar),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Raza y pelaje
                _buildInfoRow('Raza:', perro.razaPerro),
                const SizedBox(height: 4),
                _buildInfoRow('Pelaje:', perro.pelajePerro),
                const SizedBox(height: 4),
                _buildInfoRow('Actividad:', perro.actividadPerro),
                const SizedBox(height: 12),
                
                // Descripción
                Text(
                  perro.descripcionPerro,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textMedium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Fecha de ingreso
                Text(
                  'Ingreso: ${_formatDate(perro.ingresoPerro)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textLight,
                    fontSize: 11,
                  ),
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
    switch (estado.toLowerCase()) {
      case 'disponible':
        color = successGreen;
        break;
      case 'adoptado':
        color = accentBlue;
        break;
      default:
        color = grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMedium,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textDark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showPerroDetails(PerroModel perro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          perro.nombrePerro,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto del perro
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPerroImage(perro, 200),
              ),
              const SizedBox(height: 16),
              
              // Información detallada
              _buildDetailRow('Edad', '${perro.edadPerro} años'),
              _buildDetailRow('Sexo', perro.sexoPerro),
              _buildDetailRow('Raza', perro.razaPerro),
              _buildDetailRow('Pelaje', perro.pelajePerro),
              _buildDetailRow('Actividad', perro.actividadPerro),
              _buildDetailRow('Estado', perro.estadoPerro),
              const SizedBox(height: 12),
              
              // Descripción
              Text(
                'Descripción:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                perro.descripcionPerro,
                style: TextStyle(color: textMedium),
              ),
              const SizedBox(height: 12),
              
              // Fecha de ingreso
              Text(
                'Fecha de ingreso: ${_formatDate(perro.ingresoPerro)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textMedium,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: accentBlue,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textMedium),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el widget de imagen del perro con manejo de carga
  Widget _buildPerroImage(PerroModel perro, double height) {
    if (perro.fotoPerro == null || perro.fotoPerro!.isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.pets,
          size: 80,
          color: Colors.grey,
        ),
      );
    }

    if (perro.isLoadingImage) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (perro.errorLoadingImage != null) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Error al cargar imagen',
              style: TextStyle(
                color: textMedium,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si la imagen no es una URL, cargar la URL firmada
    if (!perro.fotoPerro!.startsWith('http')) {
      // Encontrar el índice del perro en la lista para cargar la imagen
      final viewModel = Provider.of<PerroViewModel>(context, listen: false);
      final index = viewModel.perros.indexOf(perro);
      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          viewModel.loadPerroImage(index);
        });
      }
      
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Image.network(
      perro.fotoPerro!,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.pets,
            size: 80,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
