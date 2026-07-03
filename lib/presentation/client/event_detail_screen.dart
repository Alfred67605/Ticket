import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/pdf_service.dart';
import '../common/widgets/video_player_widget.dart';
import '../common/widgets/app_button.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isPurchasing = false;

  Future<void> _purchaseTicket(int ticketTypeId, String paymentMethod, {String? promoCode}) async {
    setState(() => _isPurchasing = true);
    try {
      final ticketRepo = Provider.of<TicketRepository>(context, listen: false);
      final ticketModel = await ticketRepo.purchase(
        ticketTypeId: ticketTypeId,
        paymentMethod: paymentMethod,
      );

      if (mounted) {
        _showSuccessDialog(ticketModel);
      }
    } catch (e) {
      _showError('No se pudo procesar la compra: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showSuccessDialog(TicketModel ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Compra Confirmada! 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Entrada QR de Ingreso
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: ticket.qrToken,
                    version: QrVersions.auto,
                    size: 160.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Código: ${ticket.ticketCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Instrucciones según método de pago
                if (ticket.payment?.paymentMethod == 'qr') ...[
                  const Text(
                    'Escanea y guarda el ticket. El pago vía SimpleQR ha sido pre-autorizado.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ] else if (ticket.payment?.paymentMethod == 'banco') ...[
                  const Text(
                    'Pago: BNB Cuenta 100-2034948.\nSube tu comprobante en tu perfil.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'Pago en efectivo en puerta al validar este código.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                
                // Botones de Acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await PdfService.printTicket(
                            eventTitle: ticket.event.title,
                            organizer: ticket.event.organizer,
                            location: ticket.event.location,
                            date: ticket.event.eventDate.toIso8601String(),
                            ticketCode: ticket.ticketCode,
                            userName: ticket.user?.name ?? 'Cliente',
                            typeName: ticket.ticketType.name,
                            price: ticket.ticketType.price,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: const Text('PDF', style: TextStyle(color: AppColors.primaryLight)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx); // Cerrar diálogo
                          Navigator.pop(context, true); // Volver atrás a la cartelera
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Entendido', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPurchaseBottomSheet(dynamic ticketType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String promoCode = '';
        double discountPercent = 0.0;
        bool isValidating = false;
        String promoMsg = '';
        bool isPromoValid = false;
        String selectedPaymentMethod = 'qr';

        final List<Map<String, String>> paymentMethods = [
          {'value': 'qr', 'label': 'Código QR (Instantáneo)'},
          {'value': 'banco', 'label': 'Transferencia Bancaria'},
          {'value': 'efectivo', 'label': 'Efectivo en Puerta'},
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final double price = widget.event.getPriceForType(ticketType);
            final discountAmount = price * (discountPercent / 100);
            final total = price - discountAmount;

            Future<void> validatePromo(String code) async {
              if (code.trim().isEmpty) return;
              setModalState(() {
                isValidating = true;
                promoMsg = '';
              });
              try {
                final adminRepo = Provider.of<AdminRepository>(context, listen: false);
                final res = await adminRepo.validatePromoCode(code.trim());
                if (res['valid'] == true) {
                  setModalState(() {
                    discountPercent = (res['discount_percentage'] as num).toDouble();
                    promoMsg = res['message'] ?? 'Código aplicado con éxito';
                    isPromoValid = true;
                    promoCode = code.trim();
                  });
                } else {
                  setModalState(() {
                    discountPercent = 0.0;
                    promoMsg = res['message'] ?? 'Código inválido';
                    isPromoValid = false;
                  });
                }
              } catch (e) {
                setModalState(() {
                  discountPercent = 0.0;
                  promoMsg = 'Código inválido o vencido';
                  isPromoValid = false;
                });
              } finally {
                setModalState(() {
                  isValidating = false;
                });
              }
            }

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface.withOpacity(0.85) : Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.textMuted : AppColors.textMutedLight).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_cart_checkout_rounded, color: AppColors.primaryLight, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Confirmar Compra',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Detalles del boleto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticketType.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Entrada para ${widget.event.title}',
                                style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            'Bs. ${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      // Método de pago selector (de Anny)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selecciona tu método de pago:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedPaymentMethod,
                            dropdownColor: isDark ? AppColors.surface : Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? AppColors.card : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: paymentMethods.map((m) => DropdownMenuItem<String>(
                              value: m['value'],
                              child: Text(m['label']!, style: const TextStyle(fontSize: 14)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedPaymentMethod = val);
                              }
                            },
                          ),
                        ],
                      ),
                      if (selectedPaymentMethod == 'qr') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryLight),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Se generará un QR de pago de Simple en el siguiente paso para confirmar tu entrada.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (selectedPaymentMethod == 'banco') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.account_balance_rounded, color: AppColors.warning),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Transfiere a Banco BNB: 100-2034948 y guarda tu comprobante de depósito.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (selectedPaymentMethod == 'efectivo') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.payments_rounded, color: AppColors.success),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pagarás en boletería/puerta del evento al ingresar.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Cupón de descuento
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => promoCode = val,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Código promocional',
                                labelStyle: const TextStyle(fontSize: 12),
                                suffixIcon: isValidating
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => validatePromo(promoCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(80, 52),
                            ),
                            child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (promoMsg.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            promoMsg,
                            style: TextStyle(
                              color: isPromoValid ? AppColors.success : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Fila de resumen de precios
                      if (discountPercent > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Descuento aplicado:', style: TextStyle(fontSize: 13, color: AppColors.success)),
                            Text('- Bs. ${discountAmount.toStringAsFixed(2)} ($discountPercent%)',
                                style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Bs. ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón finalizar compra
                      AppButton(
                        text: 'Pagar e Ingresar',
                        isLoading: _isPurchasing,
                        onPressed: () {
                          Navigator.pop(context);
                          _purchaseTicket(ticketType.id, selectedPaymentMethod, promoCode: promoCode.isNotEmpty ? promoCode : null);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final event = widget.event;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // Elegant Header with dynamic media playback (image or video overlay)
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: isDark ? AppColors.surface : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: event.image != null && event.image!.isNotEmpty
                        ? (event.image!.startsWith('http')
                            ? Image.network(
                                event.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildPlaceholder(event.category),
                              )
                            : Image.file(
                                File(event.image!),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildPlaceholder(event.category),
                              ))
                        : _buildPlaceholder(event.category),
                  ),
                  if (event.video != null && event.video!.isNotEmpty && event.mediaPreference != 'image')
                    Positioned.fill(
                      child: VideoPlayerWidget(videoUrl: event.video!, isMuted: false),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Event Description, Artists, Tickets options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (event.isPresale)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PREVENTA ACTIVADA',
                            style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoRow(context, Icons.business_rounded, 'Organizado por', event.organizer),
                  const Divider(height: 24),
                  _infoRow(context, Icons.location_on_rounded, 'Ubicación', event.location),
                  const Divider(height: 24),
                  _infoRow(context, Icons.access_time_rounded, 'Fecha y Hora', AppDateUtils.formatFull(event.eventDate.toIso8601String())),
                  const Divider(height: 32),

                  Text(
                    'Acerca del evento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tickets pricing options
                  Text(
                    'Entradas disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: event.ticketTypes.length,
                    itemBuilder: (context, i) {
                      final type = event.ticketTypes[i];
                      final finalPrice = event.getPriceForType(type);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Stock: ${type.stock} boletos',
                                    style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (event.isPresale)
                                        Text(
                                          'Bs. ${type.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        'Bs. ${finalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: type.stock > 0 ? () => _showPurchaseBottomSheet(type) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                    child: const Text('Comprar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card : AppColors.cardBorderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String category) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C0721), AppColors.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note_rounded, size: 64, color: AppColors.primaryLight),
            const SizedBox(height: 12),
            Text(
              category.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
