import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../models/perro_model.dart';

class EditarPerroScreen extends StatefulWidget {
  final PerroModel perro;

  const EditarPerroScreen({super.key, required this.perro});

  @override
  State<EditarPerroScreen> createState() => _EditarPerroScreenState();
}

class _EditarPerroScreenState extends State<EditarPerroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _razaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _fechaIngresoController = TextEditingController();
  
  String _sexoSeleccionado = sexoMacho;
  String _pelajeSeleccionado = '';
  String _estaturaSeleccionada = 'Mediano';
  String _actividadSeleccionada = actividadMedia;
  String _estadoSeleccionado = estadoDisponible;
  DateTime _fechaIngresoSeleccionada = DateTime.now();
  
  File? _imagenSeleccionada;
  String? _imagenActualUrl;
  final ImagePicker _picker = ImagePicker();
  bool _guardando = false;
  bool _seleccionandoImagen = false;

  // Opciones para dropdowns
  final List<String> _opcionesSexo = [sexoMacho, sexoHembra];
  final List<String> _opcionesPelaje = [
    'Corto',
    'Largo',
    'Rizado',
    'Liso',
    'Áspero',
    'Suave'
  ];
  final List<String> _opcionesEstatura = [
    'Pequeño', 
    'Mediano',
    'Grande'
  ];
  final List<String> _opcionesActividad = [
    actividadBaja,
    actividadMedia,
    actividadAlta
  ];
  final List<String> _opcionesEstado = [
    estadoDisponible,
    estadoAdoptado
  ];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  void _inicializarDatos() {
    // Cargar los datos del perro existente
    _nombreController.text = widget.perro.nombrePerro;
    _edadController.text = widget.perro.edadPerro.toString();
    _razaController.text = widget.perro.razaPerro;
    _descripcionController.text = widget.perro.descripcionPerro;
    
    _sexoSeleccionado = widget.perro.sexoPerro;
    _pelajeSeleccionado = widget.perro.pelajePerro;
    _estaturaSeleccionada = widget.perro.estaturaPerro;
    _actividadSeleccionada = widget.perro.actividadPerro;
    _estadoSeleccionado = widget.perro.estadoPerro;
    _imagenActualUrl = widget.perro.fotoPerro;

    // Parsear la fecha de ingreso
    try {
      _fechaIngresoSeleccionada = DateTime.parse(widget.perro.ingresoPerro);
    } catch (e) {
      _fechaIngresoSeleccionada = DateTime.now();
    }
    _fechaIngresoController.text = _formatearFecha(_fechaIngresoSeleccionada);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _razaController.dispose();
    _descripcionController.dispose();
    _fechaIngresoController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _seleccionarFecha() async {
    try {
      final DateTime? fechaSeleccionada = await showDatePicker(
        context: context,
        initialDate: _fechaIngresoSeleccionada,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: 'Seleccionar fecha de ingreso',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
      );

      if (fechaSeleccionada != null && fechaSeleccionada != _fechaIngresoSeleccionada) {
        setState(() {
          _fechaIngresoSeleccionada = fechaSeleccionada;
          _fechaIngresoController.text = _formatearFecha(fechaSeleccionada);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar fecha: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    if (_seleccionandoImagen) return;
    
    setState(() {
      _seleccionandoImagen = true;
    });

    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = File(imagen.path);
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _seleccionandoImagen = false;
        });
      }
    }
  }

  Future<void> _actualizarPerro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final viewModel = context.read<PerroViewModel>();

      // Validar y parsear la edad
      int edadPerro;
      try {
        edadPerro = int.parse(_edadController.text.trim());
        if (edadPerro < 0 || edadPerro > 15) {
          throw Exception('La edad debe estar entre 0 y 15 años');
        }
      } catch (e) {
        _mostrarError('Error: La edad debe ser un número válido entre 0 y 15 años');
        return;
      }

      // Crear el modelo actualizado del perro
      final perroActualizado = PerroModel(
        id: widget.perro.id,
        nombrePerro: _nombreController.text.trim(),
        edadPerro: edadPerro,
        sexoPerro: _sexoSeleccionado,
        razaPerro: _razaController.text.trim(),
        pelajePerro: _pelajeSeleccionado,
        actividadPerro: _actividadSeleccionada,
        estadoPerro: _estadoSeleccionado,
        fotoPerro: widget.perro.fotoPerro, // Mantener la foto actual inicialmente
        descripcionPerro: _descripcionController.text.trim(),
        estaturaPerro: _estaturaSeleccionada,
        ingresoPerro: _fechaIngresoSeleccionada.toIso8601String(),
      );

      bool exito;
      
      // Si hay una nueva imagen seleccionada, actualizar perro con imagen
      if (_imagenSeleccionada != null) {
        exito = await viewModel.updatePerroWithImage(perroActualizado, _imagenSeleccionada!);
      } else {
        // Solo actualizar datos sin cambiar imagen
        exito = await viewModel.updatePerro(widget.perro.id!, perroActualizado);
      }

      if (exito) {
        if (mounted) {
          final mensaje = _imagenSeleccionada != null 
              ? 'Perro actualizado exitosamente con nueva imagen'
              : 'Datos del perro actualizados exitosamente';
          _mostrarExito(mensaje);
          // Retornar true para indicar que se actualizó exitosamente
          Navigator.of(context).pop(true);
        }
      } else {
        _mostrarError(viewModel.error ?? 'Error al actualizar el perro');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: errorRed,
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Editar ${widget.perro.nombrePerro}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: accentBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de imagen
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Foto del perro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(Opcional - mantener actual si no se cambia)',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: grey100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: grey300),
                    ),
                    child: _imagenSeleccionada != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imagenSeleccionada!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _imagenSeleccionada = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              // Indicador de nueva imagen
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'NUEVA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _imagenActualUrl != null && _imagenActualUrl!.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _imagenActualUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: accentBlue,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.pets,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Imagen actual',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Indicador de imagen actual
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentBlue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTUAL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : InkWell(
                                onTap: _seleccionandoImagen ? null : _seleccionarImagen,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _seleccionandoImagen
                                        ? CircularProgressIndicator(
                                            color: accentBlue,
                                          )
                                        : Icon(
                                            Icons.add_a_photo,
                                            size: 64,
                                            color: grey500,
                                          ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _seleccionandoImagen ? 'Seleccionando...' : 'Seleccionar nueva foto',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: grey600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),

              if (_imagenActualUrl != null || _imagenSeleccionada != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _seleccionandoImagen ? null : _seleccionarImagen,
                    icon: _seleccionandoImagen 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentBlue,
                            ),
                          )
                        : const Icon(Icons.photo_library),
                    label: Text(_seleccionandoImagen ? 'Seleccionando...' : 'Cambiar foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grey200,
                      foregroundColor: textDark,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Nombre del perro
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: perroNombreLabel,
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Edad y Sexo en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _edadController,
                      decoration: const InputDecoration(
                        labelText: perroEdadLabel,
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La edad es obligatoria';
                        }
                        final edad = int.tryParse(value.trim());
                        if (edad == null || edad < 0 || edad > 15) {
                          return 'Edad debe ser 0-15 años';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sexoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: perroSexoLabel,
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: _opcionesSexo.map((sexo) {
                        return DropdownMenuItem(
                          value: sexo,
                          child: Text(sexo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sexoSeleccionado = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Raza
              TextFormField(
                controller: _razaController,
                decoration: const InputDecoration(
                  labelText: perroRazaLabel,
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La raza es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pelaje y Actividad en fila
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _pelajeSeleccionado,
                      decoration: const InputDecoration(
                        labelText: perroPelajeLabel,
                        prefixIcon: Icon(Icons.brush),
                      ),
                      items: _opcionesPelaje.map((pelaje) {
                        return DropdownMenuItem(
                          value: pelaje,
                          child: Text(pelaje),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _pelajeSeleccionado = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _actividadSeleccionada,
                      decoration: const InputDecoration(
                        labelText: perroActividadLabel,
                        prefixIcon: Icon(Icons.directions_run),
                      ),
                      items: _opcionesActividad.map((actividad) {
                        return DropdownMenuItem(
                          value: actividad,
                          child: Text(actividad),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _actividadSeleccionada = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Estatura y Estado en fila
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Estatura',
                        prefixIcon: Icon(Icons.height),
                      ),
                      value: _estaturaSeleccionada,
                      items: _opcionesEstatura.map((String estatura) {
                        return DropdownMenuItem<String>(
                          value: estatura,
                          child: Text(estatura),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _estaturaSeleccionada = newValue ?? 'Mediano';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La estatura es obligatoria';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      value: _estadoSeleccionado,
                      items: _opcionesEstado.map((String estado) {
                        return DropdownMenuItem<String>(
                          value: estado,
                          child: Text(estado),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _estadoSeleccionado = newValue ?? estadoDisponible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El estado es obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fecha de Ingreso al Albergue
              TextFormField(
                controller: _fechaIngresoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Ingreso al Albergue',
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.date_range),
                ),
                readOnly: true,
                onTap: _seleccionarFecha,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La fecha de ingreso es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: perroDescripcionLabel,
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Botón de actualizar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _actualizarPerro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _guardando
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_imagenSeleccionada != null 
                                ? 'Actualizando imagen...' 
                                : 'Actualizando datos...'),
                          ],
                        )
                      : Text(
                          _imagenSeleccionada != null 
                              ? 'Actualizar con Nueva Imagen' 
                              : 'Actualizar Datos',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
