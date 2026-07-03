import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/services/pdf_service.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final ticketRepo = Provider.of<TicketRepository>(context, listen: false);
      final list = await ticketRepo.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error tickets: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':      return AppColors.success;
      case 'used':      return AppColors.textMuted;
      case 'cancelled': return AppColors.error;
      default:          return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':      return Icons.check_circle_rounded;
      case 'used':      return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default:          return Icons.schedule_rounded;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'paid':      return 'Válido';
      case 'used':      return 'Usado';
      case 'cancelled': return 'Cancelado';
      case 'pending':   return 'Pendiente';
      default:          return status;
    }
  }

  void _showQR(TicketModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Código QR',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              model.event.title,
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: QrImageView(
                data: model.qrToken,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.ticketCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Código copiado al portapapeles'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : AppColors.cardBorderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.ticketCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy_all_rounded,
                      size: 16,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.surface : AppColors.cardLight,
                      foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                      side: BorderSide(
                        color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await PdfService.printTicket(
                        eventTitle: model.event.title,
                        organizer: model.event.organizer,
                        location: model.event.location,
                        date: AppDateUtils.formatFull(model.event.eventDate.toIso8601String()),
                        ticketCode: model.ticketCode,
                        userName: model.user?.name ?? 'Cliente',
                        typeName: model.ticketType.name,
                        price: model.payment?.amount ?? model.ticketType.price,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: const Text('Imprimir PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Mis Entradas'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadTickets,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar tus tickets',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadTickets,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 80,
                            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noTickets,
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _tickets.length,
                      itemBuilder: (ctx, index) {
                        final t = _tickets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showQR(t),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Ticket representation icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _statusColor(t.status).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _statusIcon(t.status),
                                      color: _statusColor(t.status),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.event.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppDateUtils.formatFull(t.event.eventDate.toIso8601String()),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tipo: ${t.ticketType.name} • Bs. ${(t.payment?.amount ?? t.ticketType.price).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
