import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/event_model.dart';
import '../../data/models/ticket_model.dart';
import '../../data/services/pdf_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedEventReport;
  bool _isLoadingReport = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final adminRepo = Provider.of<AdminRepository>(context, listen: false);
      final data = await adminRepo.getGeneralReport();
      if (mounted) {
        setState(() {
          _events = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEventReport(int eventId) async {
    if (mounted) setState(() => _isLoadingReport = true);
    try {
      final adminRepo = Provider.of<AdminRepository>(context, listen: false);
      final data = await adminRepo.getEventReport(eventId);
      if (mounted) {
        setState(() {
          _selectedEventReport = data;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          _selectedEventReport != null ? 'Detalle de Evento' : 'Reportes y Ventas',
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () {
            if (_selectedEventReport != null) {
              setState(() => _selectedEventReport = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedEventReport != null
              ? _buildEventReport()
              : _buildGeneralReport(),
    );
  }

  Widget _buildGeneralReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalSold = _events.fold<int>(0, (sum, e) => sum + ((e['tickets_sold'] ?? 0) as int));
    final totalRevenue = _events.fold<double>(0, (sum, e) => sum + ((e['revenue'] ?? 0) as num).toDouble());

    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => ((b['revenue'] ?? 0) as num).compareTo(a['revenue'] ?? 0));
    final topEvents = sortedEvents.take(5).toList();

    double maxRevenue = 100.0;
    for (var e in topEvents) {
      double r = (e['revenue'] as num?)?.toDouble() ?? 0.0;
      if (r > maxRevenue) maxRevenue = r;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.primaryShadow(opacity: 0.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$totalSold',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Boletos Vendidos',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(width: 1.5, height: 44, color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Bs. ${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresos Totales',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // fl_chart bar chart
        if (_events.isNotEmpty) ...[
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.card.withOpacity(0.5) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.cardBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Top 5 Eventos por Ingresos (Bs.)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxRevenue * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Bs. ${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < topEvents.length) {
                                String title = (topEvents[index]['event'] as dynamic).title ?? '';
                                if (title.length > 8) title = '${title.substring(0, 6)}...';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(title, style: const TextStyle(fontSize: 8)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: topEvents.asMap().entries.map((entry) {
                        int idx = entry.key;
                        double rev = (entry.value['revenue'] as num?)?.toDouble() ?? 0.0;
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: rev,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        Expanded(
          child: _events.isEmpty
              ? const Center(child: Text('No hay datos disponibles'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _events.length,
                  itemBuilder: (ctx, i) {
                    final e = _events[i];
                    final event = e['event'] as dynamic;
                    final sold = (e['tickets_sold'] ?? 0) as int;
                    final used = (e['tickets_used'] ?? 0) as int;
                    final revenue = ((e['revenue'] ?? 0) as num).toDouble();

                    return GestureDetector(
                      onTap: () => _loadEventReport(event.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.card.withOpacity(0.55) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppColors.cardBorderLight),
                        ),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _statChip('Vendidos', '$sold', AppColors.primaryLight),
                                const SizedBox(width: 8),
                                _statChip('Asistieron', '$used', AppColors.success),
                                const SizedBox(width: 8),
                                _statChip('Ingresos', 'Bs. ${revenue.toStringAsFixed(0)}', AppColors.warning),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoadingReport) {
      return const Center(child: CircularProgressIndicator());
    }

    final report = _selectedEventReport!;
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final tickets = (report['tickets'] as List<TicketModel>?) ?? [];
    final event = report['event'] as dynamic;

    final sold = (summary['total_sold'] ?? 0) as int;
    final used = (summary['total_used'] ?? 0) as int;
    final double attendancePercent = sold > 0 ? (used / sold) : 0.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card.withOpacity(0.6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorderLight),
          ),
          child: Column(
            children: [
              Text(
                event.title,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Vendidos', '$sold', AppColors.primaryLight),
                  _summaryItem('Ingresos', 'Bs. ${((summary['total_revenue'] ?? 0) as num).toStringAsFixed(0)}', AppColors.warning),
                ],
              ),
            ],
          ),
        ),

        // Attendance Percentage Check-in
        Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card.withOpacity(0.4) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppColors.cardBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚪 Asistencia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${(attendancePercent * 100).toStringAsFixed(1)}% check-in', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                ],
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: attendancePercent,
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(attendancePercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Print Report PDF (de Anny)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final ticketDetails = tickets.map((t) => {
                      'name': t.user?.name ?? 'Cliente',
                      'type': t.ticketType.name,
                      'code': t.ticketCode,
                      'status': t.status,
                    }).toList();

                    await PdfService.printEventReport(
                      eventTitle: event.title,
                      organizer: event.organizer,
                      location: event.location,
                      date: AppDateUtils.formatFull(event.eventDate.toIso8601String()),
                      sold: sold,
                      used: used,
                      revenue: ((summary['total_revenue'] ?? 0) as num).toDouble(),
                      ticketDetails: ticketDetails,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: const Text('Exportar Reporte PDF'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: tickets.isEmpty
              ? const Center(child: Text('No hay tickets emitidos para este evento.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tickets.length,
                  itemBuilder: (ctx, i) {
                    final t = tickets[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t.user?.name ?? 'Cliente', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${t.ticketType.name} · ${t.ticketCode}', style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          t.status.toUpperCase(),
                          style: TextStyle(
                            color: t.status == 'used'
                                ? AppColors.textMuted
                                : (t.status == 'paid' ? AppColors.success : AppColors.warning),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
