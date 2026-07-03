/// Strings centralizados de la aplicación TicketPotosí.
class AppStrings {
  AppStrings._();

  // ─── App ─────────────────────────────────────────────────────────────────
  static const appName = 'TicketPotosí';
  static const appTagline = 'Tu plataforma premium de eventos';
  static const appVersion = '2.0.0';

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const login = 'Iniciar Sesión';
  static const register = 'Registrarse';
  static const logout = 'Cerrar Sesión';
  static const email = 'Correo electrónico';
  static const password = 'Contraseña';
  static const phone = 'Teléfono';
  static const name = 'Nombre completo';
  static const forgotPassword = '¿Olvidaste tu contraseña?';
  static const resetPassword = 'Restablecer contraseña';
  static const newPassword = 'Nueva contraseña';
  static const currentPassword = 'Contraseña actual';
  static const changePassword = 'Cambiar contraseña';
  static const loginHint = 'Email o teléfono';
  static const noAccount = '¿No tienes cuenta?';
  static const hasAccount = '¿Ya tienes cuenta?';

  // ─── Navegación ──────────────────────────────────────────────────────────
  static const explore = 'Explorar';
  static const myTickets = 'Mis Tickets';
  static const scanner = 'Escáner';
  static const profile = 'Perfil';
  static const chatbot = 'Asistente';
  static const admin = 'Admin';

  // ─── Eventos ─────────────────────────────────────────────────────────────
  static const events = 'Eventos';
  static const createEvent = 'Crear Evento';
  static const editEvent = 'Editar Evento';
  static const deleteEvent = 'Eliminar Evento';
  static const eventTitle = 'Título del evento';
  static const eventDescription = 'Descripción';
  static const eventLocation = 'Ubicación';
  static const eventDate = 'Fecha del evento';
  static const eventCapacity = 'Capacidad';
  static const eventOrganizer = 'Organizador';
  static const eventCategory = 'Categoría';
  static const allCategories = 'Todos';

  // ─── Tickets ─────────────────────────────────────────────────────────────
  static const buyTicket = 'Comprar Entrada';
  static const ticketType = 'Tipo de entrada';
  static const ticketCode = 'Código de ticket';
  static const ticketPrice = 'Precio';
  static const noTickets = 'No tienes tickets todavía';
  static const printPdf = 'Imprimir PDF';
  static const scanQr = 'Escanear QR';
  static const qrValid = 'Ticket válido ✅';
  static const qrInvalid = 'QR inválido';
  static const qrUsed = 'Ticket ya fue usado';
  static const presale = 'Preventa';

  // ─── Admin ───────────────────────────────────────────────────────────────
  static const dashboard = 'Dashboard';
  static const users = 'Usuarios';
  static const promotions = 'Promociones';
  static const reports = 'Reportes';
  static const settings = 'Configuración';

  // ─── Pagos ───────────────────────────────────────────────────────────────
  static const paymentCash = 'Efectivo';
  static const paymentQr = 'QR';
  static const paymentBank = 'Transferencia';
  static const paymentMethod = 'Método de pago';

  // ─── Estados ─────────────────────────────────────────────────────────────
  static const active = 'Activo';
  static const inactive = 'Inactivo';
  static const paid = 'Pagado';
  static const pending = 'Pendiente';
  static const used = 'Usado';
  static const cancelled = 'Cancelado';

  // ─── Errores ─────────────────────────────────────────────────────────────
  static const errorGeneric = 'Ha ocurrido un error. Inténtalo de nuevo.';
  static const errorConnection = 'Error de conexión. Verifica tu internet.';
  static const errorCredentials = 'Credenciales incorrectas.';
  static const errorAccountDisabled = 'Tu cuenta está desactivada.';
  static const errorNoStock = 'No hay tickets disponibles.';
  static const errorEventInactive = 'El evento no está disponible.';

  // ─── Éxito ───────────────────────────────────────────────────────────────
  static const successRegister = 'Cuenta creada correctamente';
  static const successLogin = 'Bienvenido de nuevo';
  static const successPurchase = 'Ticket comprado correctamente';
  static const successUpdate = 'Actualizado correctamente';
  static const successDelete = 'Eliminado correctamente';

  // ─── ChatBot ─────────────────────────────────────────────────────────────
  static const chatbotName = 'Potosí AI';
  static const chatbotSubtitle = 'Asistente Virtual 🤖';
  static const chatbotHint = 'Pregúntale a Potosí AI...';
  static const chatbotWelcome = '¡Hola! Soy Potosí AI 🤖, tu asistente virtual. '
      '¿En qué puedo ayudarte hoy? Te puedo recomendar eventos, '
      'informarte sobre preventas o ayudarte con tus tickets.';
}
