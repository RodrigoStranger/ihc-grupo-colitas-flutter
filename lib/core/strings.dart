// Títulos generales de la aplicación
const String appTitle = 'Grupo Colitas Arequipa';
const String appVersionPrefix = 'Versión';

// --- PANTALLA DE INICIO DE SESIÓN ---
const String loginPanelTitle = 'Panel de Administración';
const String loginEmailLabel = 'Correo electrónico';
const String loginPasswordLabel = 'Contraseña';
const String loginButtonText = 'Iniciar Sesión';

// Mensajes de error para el login
const String loginErrorInvalidCredentials = 'Usuario o contraseña no existentes';
const String loginErrorEmptyEmail = 'Por favor, ingresa tu correo electrónico';
const String loginErrorInvalidEmail = 'Ingresa un correo electrónico válido';
const String loginErrorEmptyPassword = 'Por favor, ingresa tu contraseña';

// --- MENÚ PRINCIPAL ---
const String mainMenuTitle = 'Menú Principal';
const String mainMenuWelcome = 'Bienvenid@ al Grupo Colitas Arequipa';
const String mainMenuSubtitle = 'Selecciona una de las opciones para acceder a la funcionalidad correspondiente.';
const String menuWelcomeTitle = 'Bienvenid@';
const String menuWelcomeSubtitle = 'Selecciona una opción para continuar';
const String menuOptionsTitle = 'Opciones del Menú';

// Opciones del menú
const String menuOptionAdoptionsTitle = 'Adopciones';
const String menuOptionEventsTitle = 'Eventos';
const String menuOptionVolunteeringTitle = 'Voluntariado';
const String menuOptionDonationsTitle = 'Donaciones';

// Descripciones de opciones
const String menuDonacionesTitle = 'Gestión de Donaciones';
const String menuDonacionesDesc = 'Visualiza y administra las solicitudes de donaciones.';
const String menuAdopcionesTitle = 'Gestión de Adopciones';
const String menuAdopcionesDesc = 'Gestiona solicitudes de adopción de animales del Grupo Colitas.';
const String menuCampanasTitle = 'Gestión de Campañas';
const String menuCampanasDesc = 'Visualiza la campaña actual del Grupo Colitas.';
const String menuAnimalesTitle = 'Gestión de Animales';
const String menuAnimalesDesc = 'Registra y administra los animales del refugio del Grupo Colitas.';

// --- PANTALLA DE CAMPAÑAS ---
const String campanasNoRegistradas = 'No hay campañas registradas.';
const String campanasMotivoLabel = 'Motivo: ';
const String campanasFechaLabel = 'Fecha: ';
const String campanasCargandoMas = 'Cargando más firmas...';
const String campanasErrorCargar = 'Error al cargar las firmas: ';

// --- PANTALLA DE DETALLE DE FIRMA ---
const String firmaDetalleTitulo = 'Detalle de Firma';
const String firmaNombreLabel = 'Nombre: ';
const String firmaDniLabel = 'DNI: ';
const String firmaTelefonoLabel = 'Teléfono: ';
const String firmaCorreoLabel = 'Correo: ';
const String firmaMotivoLabel = 'Motivo: ';
const String firmaLabel = 'Firma:';
const String firmaErrorCargar = 'Error al cargar la imagen de la firma';
const String firmaFechaRegistroLabel = 'Fecha de registro:';

// Estados de carga de imagen
const String imagenCargando = 'Cargando imagen...';
const String imagenErrorCarga = 'Error al cargar la imagen';
const String imagenNoDisponible = 'Imagen no disponible';
const String cargandoFirmas = 'Cargando firmas';

// Botones y acciones
const String botonAceptar = 'Aceptar';
const String botonCancelar = 'Cancelar';
const String botonCerrar = 'Cerrar';
const String botonReintentar = 'Reintentar';
const String botonRecargar = 'Recargar';

// Mensajes de error generales
const String errorInesperado = 'Ha ocurrido un error inesperado';
const String errorConexion = 'Error de conexión. Verifica tu conexión a internet';
const String errorPermisos = 'No tienes permisos para realizar esta acción';

// Validaciones
const String validacionCampoRequerido = 'Este campo es requerido';
const String validacionEmailInvalido = 'Ingresa un correo electrónico válido';
const String validacionMinCaracteres = 'Debe tener al menos %d caracteres';
const String validacionMaxCaracteres = 'No debe exceder los %d caracteres';

// --- PANTALLA DE PERROS ---
const String perrosNoRegistrados = 'No hay perros registrados en el refugio.';
const String perrosCargando = 'Cargando perros...';
const String perrosErrorCargar = 'Error al cargar los perros';

// --- PANTALLA DE AGREGAR PERRO ---
const String agregarPerroTitulo = 'Agregar Nuevo Perro';
const String perroNombreLabel = 'Nombre del perro';
const String perroEdadLabel = 'Edad (años)';
const String perroSexoLabel = 'Sexo';
const String perroRazaLabel = 'Raza';
const String perroPelajeLabel = 'Tipo de pelaje';
const String perroActividadLabel = 'Nivel de actividad';
const String perroEstadoLabel = 'Estado';
const String perroDescripcionLabel = 'Descripción';
const String perroFotoLabel = 'Foto del perro';
const String seleccionarFoto = 'Seleccionar foto';
const String cambiarFoto = 'Cambiar foto';
const String guardandoPerro = 'Guardando perro...';
const String perroGuardadoExito = 'Perro guardado exitosamente';
const String errorGuardarPerro = 'Error al guardar el perro';
const String errorSubirImagen = 'Error al subir la imagen';
const String seleccionarImagenRequerida = 'Debe seleccionar una imagen del perro';

// Opciones para campos de perro
const String sexoMacho = 'Macho';
const String sexoHembra = 'Hembra';
const String estadoDisponible = 'Disponible';
const String estadoAdoptado = 'Adoptado';
const String estadoTratamiento = 'En Tratamiento';
const String actividadBaja = 'Baja';
const String actividadMedia = 'Media';
const String actividadAlta = 'Alta';

// --- PANTALLA DE SOLICITUDES DE ADOPCIÓN ---
const String solicitudesAdopcionTitulo = 'Solicitudes de Adopción';
const String solicitudesNoRegistradas = 'No hay solicitudes de adopción registradas.';
const String solicitudesCargando = 'Cargando solicitudes...';
const String solicitudesErrorCargar = 'Error al cargar las solicitudes';
const String solicitudNombreLabel = 'Solicitante: ';
const String solicitudPerroLabel = 'Perro: ';
const String solicitudEstadoLabel = 'Estado: ';
const String solicitudFechaLabel = 'Fecha: ';
const String solicitudTelefono1Label = 'Teléfono 1: ';
const String solicitudTelefono2Label = 'Teléfono 2: ';
const String solicitudDescripcionLabel = 'Descripción: ';

// Botones de acción para solicitudes
const String botonAceptarSolicitud = 'Aceptar';
const String botonRechazarSolicitud = 'Rechazar';
const String botonContactarWhatsApp = 'Contactar';

// Estados de solicitudes
const String estadoPendiente = 'Pendiente';
const String estadoAceptado = 'Aceptado';
const String estadoRechazado = 'Rechazado';

// Mensajes de procesamiento
const String procesandoSolicitud = 'Procesando solicitud...';
const String solicitudAceptadaExito = 'Solicitud aceptada exitosamente';
const String solicitudRechazadaExito = 'Solicitud rechazada exitosamente';
const String errorAceptarSolicitud = 'Error al aceptar la solicitud';
const String errorRechazarSolicitud = 'Error al rechazar la solicitud';

// Confirmaciones
const String confirmarAceptarSolicitud = '¿Estás seguro de que deseas aceptar esta solicitud de adopción?';
const String confirmarRechazarSolicitud = '¿Estás seguro de que deseas rechazar esta solicitud de adopción?';
const String tituloConfirmacion = 'Confirmar acción';

// WhatsApp
const String abrirWhatsApp = 'Abrir WhatsApp';
const String seleccionarTelefono = 'Seleccionar teléfono';

// Filtros de solicitudes
const String filtroTodos = 'Todos';
const String filtroPendiente = 'Pendiente';
const String filtroAceptado = 'Aceptado';
const String filtroRechazado = 'Rechazado';
const String filtrandoLabel = 'Filtrando: ';
const String cambiarFiltroHint = 'Intenta cambiar el filtro';
const String noHaySolicitudesFiltro = 'No hay solicitudes';