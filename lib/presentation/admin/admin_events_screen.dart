import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/models/event_model.dart';
import 'create_event_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final eventRepo = Provider.of<EventRepository>(context, listen: false);
      final list = await eventRepo.getEvents(showAll: true);
      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(int id, String title) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.card : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? BorderSide(color: Colors.white.withOpacity(0.08)) : BorderSide.none,
        ),
        title: const Text('Eliminar evento', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar "$title"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final eventRepo = Provider.of<EventRepository>(context, listen: false);
        await eventRepo.deleteEvent(id);
        _showMessage('Evento eliminado');
        _loadEvents();
      } catch (e) {
        _showMessage('Error al eliminar: $e', isError: true);
      }
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'active': return '🟢 Activo';
      case 'inactive': return '🟡 Inactivo';
      case 'cancelled': return '🔴 Cancelado';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Gestión de Eventos'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (result == true) _loadEvents();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _events.length,
                    itemBuilder: (ctx, i) => _buildEventCard(_events[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
          const SizedBox(height: 16),
          Text(
            'No hay eventos',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Crea el primer evento con el botón +', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel eventModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minPrice = eventModel.ticketTypes.isNotEmpty
        ? eventModel.ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventModel.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eventModel.organizer,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                      Text(
                        _formatStatus(eventModel.status),
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    eventModel.location,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bs. ${minPrice.toStringAsFixed(2)}+',
                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEventScreen(eventModel: eventModel),
                        ),
                      );
                      if (result == true) _loadEvents();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Editar', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteEvent(eventModel.id, eventModel.title),
                    icon: const Icon(Icons.delete_rounded, size: 16, color: AppColors.error),
                    label: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
