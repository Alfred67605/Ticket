import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/event_model.dart';
import 'admin_events_screen.dart';
import 'admin_users_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_reports_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final adminRepo = Provider.of<AdminRepository>(context, listen: false);
      final data = await adminRepo.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Panel Admin'),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primaryLight,
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: isDark
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0C0721), AppColors.bg],
                        ),
                      )
                    : null,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Resumen General',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildStatsGrid(),
                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Icon(Icons.construction_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Gestión del Sistema',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildManagementGrid(),
                      const SizedBox(height: 28),

                      if (_stats['recent_events'] != null && (_stats['recent_events'] as List).isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Eventos Recientes',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildRecentEvents(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      {
        'label': 'Tickets Vendidos',
        'value': '${_stats['total_tickets'] ?? 0}',
        'icon': Icons.confirmation_number_rounded,
        'color': AppColors.primary,
      },
      {
        'label': 'Tickets Usados',
        'value': '${_stats['used_tickets'] ?? 0}',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.success,
      },
      {
        'label': 'Eventos Activos',
        'value': '${_stats['total_events'] ?? 0}',
        'icon': Icons.event_rounded,
        'color': AppColors.warning,
      },
      {
        'label': 'Usuarios Registrados',
        'value': '${_stats['total_users'] ?? 0}',
        'icon': Icons.people_rounded,
        'color': AppColors.primaryLight,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card.withOpacity(0.55) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? color.withOpacity(0.25) : color.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManagementGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      {
        'label': 'Eventos',
        'subtitle': 'Crear, editar, eliminar',
        'icon': Icons.event_rounded,
        'color': AppColors.primary,
        'screen': const AdminEventsScreen(),
      },
      {
        'label': 'Usuarios',
        'subtitle': 'Gestionar cuentas',
        'icon': Icons.people_rounded,
        'color': AppColors.primaryLight,
        'screen': const AdminUsersScreen(),
      },
      {
        'label': 'Promociones',
        'subtitle': 'Descuentos y ofertas',
        'icon': Icons.local_offer_rounded,
        'color': AppColors.warning,
        'screen': const AdminPromotionsScreen(),
      },
      {
        'label': 'Reportes',
        'subtitle': 'Ventas y asistencia',
        'icon': Icons.bar_chart_rounded,
        'color': AppColors.success,
        'screen': const AdminReportsScreen(),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: options.map((opt) {
        final color = opt['color'] as Color;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => opt['screen'] as Widget),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: isDark ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(opt['icon'] as IconData, color: color, size: 26),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['subtitle'] as String,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentEvents() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<EventModel> events = (_stats['recent_events'] as List<EventModel>?) ?? [];
    return Column(
      children: events.map((event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card.withOpacity(0.55) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.location} · ${event.category}',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.25)),
                ),
                child: Text(
                  '${event.ticketsAvailable} disp',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
