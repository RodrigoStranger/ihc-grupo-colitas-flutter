import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/perro_viewmodel.dart';
import '../models/perro_model.dart';

class AgregarPerroScreen extends StatefulWidget {
  const AgregarPerroScreen({super.key});

  @override
  State<AgregarPerroScreen> createState() => _AgregarPerroScreenState();
}

class _AgregarPerroScreenState extends State<AgregarPerroScreen> {
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
  final String _estadoSeleccionado = estadoDisponible;
  DateTime _fechaIngresoSeleccionada = DateTime.now();
  
  File? _imagenSeleccionada;
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

  @override
  void initState() {
    super.initState();
    _pelajeSeleccionado = _opcionesPelaje.first;
    // Inicializar la fecha de ingreso con la fecha actual
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
    // Evitar múltiples llamadas simultáneas
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
      // Manejar errores del selector de imágenes
      _mostrarError('Error al seleccionar imagen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _seleccionandoImagen = false;
        });
      }
    }
  }

  Future<void> _guardarPerro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imagenSeleccionada == null) {
      _mostrarError(seleccionarImagenRequerida);
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final viewModel = context.read<PerroViewModel>();

      // Validar que todos los campos requeridos estén completos
      if (_nombreController.text.trim().isEmpty ||
          _edadController.text.trim().isEmpty ||
          _razaController.text.trim().isEmpty ||
          _descripcionController.text.trim().isEmpty ||
          _pelajeSeleccionado.isEmpty ||
          _estaturaSeleccionada.isEmpty) {
        _mostrarError('Todos los campos son obligatorios');
        return;
      }

      // Validar y parsear la edad antes de crear el modelo
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

      // Crear el nombre del archivo basado en el nombre del perro y timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreArchivo = '${_nombreController.text.trim().toLowerCase()}_$timestamp.png';

      // Crear el modelo del perro (temporalmente con el nombre del archivo) aqui ponemos el nombre del archivo
      final perro = PerroModel(
        nombrePerro: _nombreController.text.trim(),
        edadPerro: edadPerro,
        sexoPerro: _sexoSeleccionado,
        razaPerro: _razaController.text.trim(),
        pelajePerro: _pelajeSeleccionado,
        actividadPerro: _actividadSeleccionada,
        estadoPerro: _estadoSeleccionado,
        fotoPerro: nombreArchivo, // Temporalmente el nombre del archivo
        descripcionPerro: _descripcionController.text.trim(),
        estaturaPerro: _estaturaSeleccionada,
        ingresoPerro: _fechaIngresoSeleccionada.toIso8601String(),
      );

      // Validar el modelo antes de enviarlo
      if (!perro.isValid()) {
        throw Exception('Los datos del perro no son válidos');
      }

      // Crear el perro con la imagen (esto subirá la imagen y actualizará la URL)
      final exito = await viewModel.createPerroWithImage(perro, _imagenSeleccionada!);

      if (exito) {
        if (mounted) {
          _mostrarExito(perroGuardadoExito);
          // Retornar true para indicar que se creó un perro exitosamente
          Navigator.of(context).pop(true);
        }
      } else {
        _mostrarError(viewModel.error ?? errorGuardarPerro);
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
        title: const Text(
          agregarPerroTitulo,
          style: TextStyle(
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
                              _seleccionandoImagen ? 'Seleccionando...' : seleccionarFoto,
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
          
          if (_imagenSeleccionada != null) ...[
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
                label: Text(_seleccionandoImagen ? 'Seleccionando...' : cambiarFoto),
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

          // Estatura
          DropdownButtonFormField<String>(
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

          // Botón de guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardarPerro,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _guardando
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(guardandoPerro),
                      ],
                    )
                  : const Text(
                      'Guardar Perro',
                      style: TextStyle(
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
