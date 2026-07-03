import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  List<EventModel> _availableEvents = [];
  String _geminiApiKey = '';
  GenerativeModel? _generativeModel;

  final List<String> _suggestions = [
    '🎪 ¿Qué eventos hay hoy?',
    '🎟️ ¿Cómo imprimo mi ticket?',
    '💰 ¿Hay descuentos o preventas?',
    '❓ ¿Cómo funciona el código QR?',
  ];

  @override
  void initState() {
    super.initState();
    _loadEventsAndKey();
    _messages.add({
      'isUser': false,
      'text': AppStrings.chatbotWelcome,
      'time': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEventsAndKey() async {
    try {
      final eventRepo = Provider.of<EventRepository>(context, listen: false);
      final list = await eventRepo.getEvents();
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('gemini_api_key') ?? '';

      setState(() {
        _availableEvents = list;
        _geminiApiKey = key;
        if (key.isNotEmpty) {
          _generativeModel = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: key,
          );
        }
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    // Simular procesamiento
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;

      String aiResponse = '';
      if (_generativeModel != null) {
        try {
          // Generar contexto de eventos en Potosí para pasar a Gemini
          final eventsContext = _availableEvents.map((e) => 
            'Evento: ${e.title}, Lugar: ${e.location}, Fecha: ${e.eventDate}, Categoría: ${e.category}, Capacidad: ${e.capacity}, Preventa disponible: ${e.isPresale ? "Sí" : "No"}'
          ).join('\n');

          final prompt = 'Eres Potosí AI, el asistente virtual oficial de la plataforma TicketPotosí en Potosí, Bolivia. '
              'Usa la siguiente información de eventos disponibles actualmente para responder a la consulta del usuario de forma amable y profesional. '
              'Si el usuario pregunta por eventos, recomiéndale los de esta lista. Si pregunta por tickets o QR, explica los pasos (pestaña Mis Tickets, etc.).\n'
              '--- Eventos Disponibles ---\n$eventsContext\n'
              '--- Consulta del Usuario ---\n$text';

          final content = [Content.text(prompt)];
          final response = await _generativeModel!.generateContent(content);
          aiResponse = response.text ?? 'Lo siento, no pude procesar tu solicitud.';
        } catch (e) {
          aiResponse = _generateFallbackResponse(text) + '\n\n*(Nota: Hubo un error al conectar con Gemini API, mostrando respuesta offline)*';
        }
      } else {
        aiResponse = _generateFallbackResponse(text);
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': aiResponse,
            'time': DateTime.now(),
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateFallbackResponse(String query) {
    final text = query.toLowerCase();

    if (text.contains('evento') ||
        text.contains('que hay') ||
        text.contains('concierto') ||
        text.contains('deporte') ||
        text.contains('teatro') ||
        text.contains('lista')) {
      if (_availableEvents.isEmpty) {
        return 'Actualmente no tengo eventos registrados en la cartelera de Potosí. ¡Vuelve a consultar más tarde!';
      }
      var resp = '🎪 ¡Claro! Estos son los eventos destacados ahora mismo en Potosí:\n\n';
      for (var e in _availableEvents) {
        resp += '• *${e.title}*\n  📍 Lugar: ${e.location}\n  📅 Fecha: ${e.eventDate}\n';
        if (e.isPresale) {
          resp += '  🔥 ¡Tiene preventa disponible!\n';
        }
        resp += '\n';
      }
      resp += 'Puedes ver los detalles completos y comprar tus entradas en la pestaña principal de Explorar.';
      return resp;
    }

    if (text.contains('ticket') ||
        text.contains('boleto') ||
        text.contains('imprimir') ||
        text.contains('descargar') ||
        text.contains('pdf')) {
      return '🎟️ Para ver e imprimir tus tickets:\n\n'
          '1. Ve a la pestaña **"Mis Tickets"** en la barra inferior de la pantalla principal.\n'
          '2. Selecciona el boleto que compraste.\n'
          '3. Verás el código QR y un botón que dice **"Imprimir PDF"**.\n'
          '4. Presiona el botón para generar el boleto digital en PDF para imprimirlo o guardarlo en tu teléfono.';
    }

    if (text.contains('preventa') ||
        text.contains('descuento') ||
        text.contains('promo') ||
        text.contains('cupón') ||
        text.contains('barato')) {
      final presales = _availableEvents.where((e) => e.isPresale).toList();
      if (presales.isEmpty) {
        return 'Actualmente no hay preventas activas en la aplicación. Sin embargo, mantente atento porque los organizadores publican ofertas regularmente.';
      }
      var resp = '💰 ¡Sí! Tenemos eventos con precios de preventa especiales ahora mismo:\n\n';
      for (var e in presales) {
        resp += '• *${e.title}* (organizado por ${e.organizer})\n';
      }
      resp += '\nPara aprovecharlos, simplemente ve a los detalles del evento y dale a "Comprar". ¡El descuento se aplicará automáticamente!';
      return resp;
    }

    if (text.contains('qr') || text.contains('validar') || text.contains('puerta') || text.contains('ingreso')) {
      return '❓ ¿Cómo funciona el código QR de ingreso?\n\n'
          '• Al comprar una entrada, se genera un código QR único para ti.\n'
          '• El día del evento, el personal encargado escaneará tu código QR.\n'
          '• **Importante**: Una vez escaneado en puerta, el QR se marcará como "Utilizado" en el sistema y no podrá reutilizarse, garantizando la seguridad del evento.';
    }

    return 'Entiendo. Como tu asistente de TicketPotosí, te sugiero que explores la cartelera de eventos o accedas a la pestaña de "Mis Tickets" si ya realizaste una compra. ¿Tienes alguna consulta específica sobre algún evento?';
  }

  void _showApiKeyConfig() {
    final controller = TextEditingController(text: _geminiApiKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
        title: const Text('Configurar Gemini API Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu API Key de Gemini para activar respuestas inteligentes contextuales reales por IA.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final key = controller.text.trim();
              await prefs.setString('gemini_api_key', key);
              if (mounted) {
                Navigator.pop(context);
                _loadEventsAndKey();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración de API Key guardada')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.chatbotName,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppStrings.chatbotSubtitle,
                  style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showApiKeyConfig,
            icon: const Icon(Icons.key_rounded, color: AppColors.primary),
            tooltip: 'Configurar IA',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isUser = msg['isUser'] == true;
                return _buildMessageBubble(msg['text'], isUser);
              },
            ),
          ),

          if (!_isTyping && _messages.length < 5) _buildSuggestionsList(),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Row(
                children: [
                  Text(
                    'Potosí AI está escribiendo...',
                    style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : (isDark ? AppColors.card : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: !isUser
              ? Border.all(color: isDark ? AppColors.cardBorder : Colors.transparent)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (ctx, i) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () => _handleSendMessage(_suggestions[i].substring(4)),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.card : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  _suggestions[i],
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppStrings.chatbotHint,
                hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 13),
                filled: true,
                fillColor: isDark ? AppColors.card : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _handleSendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSendMessage(_msgCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
