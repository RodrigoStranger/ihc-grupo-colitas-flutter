import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/colors.dart';
import '../core/strings.dart';
import '../core/cache_config.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../models/perro_model.dart';
import 'perro_detalle_screen.dart';

class PerrosScreen extends StatefulWidget {
  const PerrosScreen({super.key});

  @override
  State<PerrosScreen> createState() => _PerrosScreenState();
}

class _PerrosScreenState extends State<PerrosScreen> {
  String _filtroEstado = 'Todos'; // Filtro seleccionado
  final List<String> _opcionesFiltro = ['Todos', 'Disponible', 'Adoptado'];
  
  @override
  void initState() {
    super.initState();
    // Usar el ViewModel global y cargar datos si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<PerroViewModel>();
        if (viewModel.perros.isEmpty) {
          // Usar el método optimizado para la primera carga
          viewModel.initializeWithOptimizedImageLoading();
        } else {
          // Si ya hay perros cargados, pre-cargar las imágenes visibles
          _precacheVisibleImages(viewModel.perros);
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
          // Lista de perros
          Expanded(
            child: Consumer<PerroViewModel>(
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

            final perrosFiltrados = _filtrarPerros(viewModel.perros);
            
            // Precargar imágenes para mejor rendimiento
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _precacheVisibleImages(perrosFiltrados);
            });
            
            if (perrosFiltrados.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                        'No hay perros $_filtroEstado'.toLowerCase(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intenta cambiar el filtro',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                itemCount: perrosFiltrados.length,
                itemBuilder: (context, index) {
                  final perro = perrosFiltrados[index];
                  return _buildPerroCard(perro);
                },
              ),
            );
          },
        ),
          ),
        ],
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Imagen del perro
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: perro.fotoPerro != null && 
                           perro.fotoPerro!.isNotEmpty && 
                           perro.fotoPerro!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: perro.fotoPerro!,
                            fit: BoxFit.cover,
                            cacheManager: CustomCacheManager.thumbnailInstance, // Usar cache optimizado para thumbnails
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: _buildShimmerPlaceholder(),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                            memCacheWidth: 150, // Optimizar para lista (más pequeño)
                            memCacheHeight: 150,
                            // Configuración de caché agresiva
                            cacheKey: perro.fotoPerro!.split('/').last, // Usar nombre de archivo como key
                            fadeInDuration: const Duration(milliseconds: 150), // Más rápido
                            fadeOutDuration: const Duration(milliseconds: 50),
                          )
                        : perro.isLoadingImage
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: accentBlue,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.pets,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información del perro
                Expanded(
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
                const Icon(Icons.arrow_forward_ios, size: 18, color: grey400),
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

  // Función para filtrar perros por estado
  List<PerroModel> _filtrarPerros(List<PerroModel> perros) {
    if (_filtroEstado == 'Todos') {
      return perros;
    }
    return perros.where((perro) => perro.estadoPerro.toLowerCase() == _filtroEstado.toLowerCase()).toList();
  }

  void _showPerroDetails(PerroModel perro) {
    final viewModel = context.read<PerroViewModel>();
    // Encontrar el índice del perro para pasarlo a la pantalla de detalle
    final index = viewModel.perros.indexOf(perro);
    
    // Pre-cargar la imagen para edición rápida
    viewModel.preloadPerroImageForEditing(perro.fotoPerro);
    
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

  // Método para precargar imágenes de la lista visible
  void _precacheVisibleImages(List<PerroModel> perros) {
    for (int i = 0; i < perros.length && i < 8; i++) { // Solo las primeras 8 (pantalla visible)
      final perro = perros[i];
      if (perro.fotoPerro != null && 
          perro.fotoPerro!.isNotEmpty && 
          perro.fotoPerro!.startsWith('http')) {
        try {
          // Pre-cargar en el cache de Flutter
          precacheImage(
            CachedNetworkImageProvider(
              perro.fotoPerro!,
              cacheManager: CustomCacheManager.thumbnailInstance,
            ),
            context,
            onError: (exception, stackTrace) {
              // Ignorar errores de pre-cache silenciosamente
            },
          );
        } catch (e) {
          // Ignorar errores de pre-cache silenciosamente
        }
      }
    }
  }

  // Widget shimmer placeholder para carga de imágenes más suave
  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 24,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
