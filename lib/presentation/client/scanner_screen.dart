import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    await _scannerCtrl.stop();

    final qrToken = barcode!.rawValue!;

    try {
      final ticketRepo = Provider.of<TicketRepository>(context, listen: false);
      final response = await ticketRepo.validateQR(qrToken);
      if (mounted) {
        _showResultDialog(response);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog({
          'valid': false,
          'message': 'Error al procesar la validación local: $e',
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final isValid = result['valid'] == true;
    final ticket = result['ticket'] as TicketModel?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.card : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isValid ? AppColors.success : AppColors.error,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isValid ? AppColors.success : AppColors.error).withOpacity(0.15),
                ),
                child: Icon(
                  isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 48,
                  color: isValid ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isValid ? '✅ TICKET VÁLIDO' : '❌ TICKET INVÁLIDO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isValid ? AppColors.success : AppColors.error,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result['message'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),

              if (ticket != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.event_rounded, ticket.event.title),
                      _detailRow(Icons.person_rounded, ticket.user?.name ?? 'Cliente'),
                      _detailRow(Icons.local_activity_rounded, ticket.ticketType.name),
                      _detailRow(Icons.confirmation_number_rounded, ticket.ticketCode),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _scannerCtrl.start();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? AppColors.success : AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Continuar Escaneando',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Validar Entradas'),
        centerTitle: true,
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // Scanner Overlay Mask
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Message Info Layer
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryLight, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Encuadra el código QR en la zona para validarlo.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
