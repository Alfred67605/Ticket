import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../common/widgets/video_player_widget.dart';
import 'event_detail_screen.dart';
import 'my_tickets_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/admin_events_screen.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_promotions_screen.dart';
import '../admin/admin_reports_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<EventModel> _events = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentIndex = 0;
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Todos', 'icon': Icons.apps_rounded},
    {'label': 'Conciertos', 'icon': Icons.music_note_rounded},
    {'label': 'Deportes', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Teatro', 'icon': Icons.theater_comedy_rounded},
    {'label': 'Festivales', 'icon': Icons.celebration_rounded},
    {'label': 'Cultura', 'icon': Icons.account_balance_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final eventRepo = Provider.of<EventRepository>(context, listen: false);
      final list = await eventRepo.getEvents();
      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error eventos: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  List<EventModel> get _filtered {
    if (_selectedCategory == 0) return _events;
    final cat = _categories[_selectedCategory]['label'].toString().toLowerCase();
    return _events.where((e) {
      final combined = '${e.title} ${e.description} ${e.category}'.toLowerCase();
      if (cat == 'conciertos') return combined.contains('concierto') || combined.contains('música') || combined.contains('musica') || combined.contains('show') || combined.contains('banda');
      if (cat == 'deportes')   return combined.contains('deporte') || combined.contains('fútbol') || combined.contains('futbol') || combined.contains('torneo');
      if (cat == 'teatro')     return combined.contains('teatro') || combined.contains('obra') || combined.contains('drama');
      if (cat == 'festivales') return combined.contains('festival') || combined.contains('feria');
      if (cat == 'cultura')    return combined.contains('cultura') || combined.contains('arte') || combined.contains('museo');
      return true;
    }).toList();
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark ? BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5) : BorderSide.none,
        ),
        title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Seguro que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _buildHome(user.name),
      const MyTicketsScreen(),
      if (authProvider.isAdmin) const ScannerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      extendBody: true,
      drawer: _buildDrawer(user.name, user.roleId == 1 ? 'Administrador' : 'Cliente', authProvider.isAdmin),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(authProvider.isAdmin),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen()),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildDrawer(String name, String role, bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: isDark ? AppColors.surface : AppColors.surfaceLight,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            accountEmail: Text(
              role,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.explore_rounded, color: AppColors.primary),
                  title: Text('Explorar Eventos', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary),
                  title: Text('Mis Tickets', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                  title: Text('Asistente Potosí AI', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                  title: Text('Mi Perfil', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = isAdmin ? 3 : 2);
                  },
                ),

                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'ADMINISTRACIÓN',
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                    title: Text('Panel de Control', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_rounded, color: AppColors.primary),
                    title: Text('Gestionar Eventos', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_rounded, color: AppColors.primary),
                    title: Text('Gestionar Usuarios', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_offer_rounded, color: AppColors.primary),
                    title: Text('Gestionar Promociones', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPromotionsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                    title: Text('Reportes de Ventas', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
                    },
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Cerrar Sesión', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <Map<String, dynamic>>[
      {'active': Icons.explore_rounded, 'inactive': Icons.explore_outlined, 'label': 'Explorar'},
      {'active': Icons.confirmation_number_rounded, 'inactive': Icons.confirmation_number_outlined, 'label': 'Mis Tickets'},
      if (isAdmin)
        {'active': Icons.qr_code_scanner_rounded, 'inactive': Icons.qr_code_outlined, 'label': 'Scanner'},
      {'active': Icons.person_rounded, 'inactive': Icons.person_outline_rounded, 'label': 'Perfil'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
            blurRadius: 30,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface.withOpacity(0.75) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isSelected = _currentIndex == i;

                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item['active'] as IconData : item['inactive'] as IconData,
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                  : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHome(String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NestedScrollView(
      headerSliverBuilder: (context, innerScrolled) => [
        SliverAppBar(
          backgroundColor: isDark ? AppColors.surface.withOpacity(0.85) : Colors.white.withOpacity(0.85),
          floating: true,
          snap: true,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight, size: 26),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú principal',
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Divider(height: 0.5, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          title: Text(
            AppStrings.appName,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loadEvents,
              icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight, size: 24),
              tooltip: 'Actualizar eventos',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C0721), AppColors.bg],
                ),
              )
            : null,
        child: Column(
          children: [
            // Categories Horizontal List
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final isSelected = _selectedCategory == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.card.withOpacity(0.6) : AppColors.cardLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.12)
                              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
                          width: 1,
                        ),
                        boxShadow: isSelected ? AppColors.primaryShadow(opacity: 0.2) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _categories[i]['icon'] as IconData,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _categories[i]['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Events List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? _buildErrorState()
                      : _filtered.isEmpty
                          ? _buildEmptyState()
                          : _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withOpacity(0.8)),
          const SizedBox(height: 16),
          const Text('Error al cargar eventos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 52, color: AppColors.textMuted.withOpacity(0.7)),
          const SizedBox(height: 16),
          const Text('No se encontraron eventos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final list = _filtered;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, i) {
        return _EventCard(
          event: list[i],
          onTap: () async {
            final refresh = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailScreen(event: list[i])),
            );
            if (refresh == true) {
              _loadEvents();
            }
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card.withOpacity(0.55) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.isPresale)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                            ),
                            child: const Text(
                              'PREVENTA',
                              style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.organizer,
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoChip(context, Icons.location_on_rounded, event.location),
                    const SizedBox(height: 8),
                    _infoChip(context, Icons.access_time_rounded, AppDateUtils.formatFull(event.eventDate.toIso8601String())),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.success.withOpacity(0.25)),
                          ),
                          child: Text(
                            '${event.ticketsAvailable} disponibles',
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.primaryShadow(opacity: 0.2),
                          ),
                          child: const Row(
                            children: [
                              Text('Ver detalles', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: _buildEventImage(context),
        ),

        // Video Player Overlay (Alfred style)
        if (event.video != null && event.video!.isNotEmpty && event.mediaPreference != 'image')
          Positioned.fill(
            child: VideoPlayerWidget(videoUrl: event.video!),
          ),

        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_activity_rounded, size: 13, color: AppColors.primaryLight),
                const SizedBox(width: 5),
                Text(
                  '${event.ticketsAvailable} tickets',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventImage(BuildContext context) {
    if (event.image == null || event.image!.isEmpty) {
      return _gradientHeader();
    }
    
    if (event.image!.startsWith('http')) {
      return Image.network(
        event.image!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientHeader(),
      );
    }
    
    if (kIsWeb) {
      if (event.image!.startsWith('assets/')) {
        return Image.asset(
          event.image!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientHeader(),
        );
      }
      return _gradientHeader();
    }

    if (event.image!.startsWith('assets/')) {
      return Image.asset(
        event.image!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientHeader(),
      );
    }
    
    try {
      return Image.file(
        File(event.image!),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientHeader(),
      );
    } catch (e) {
      debugPrint('Error al cargar imagen en tarjeta: $e');
      return _gradientHeader();
    }
  }

  Widget _gradientHeader() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF02040A), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.theater_comedy_rounded, size: 40, color: Color(0xFFFFD700)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                event.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 15, color: isDark ? AppColors.primaryLight.withOpacity(0.85) : AppColors.primary.withOpacity(0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
