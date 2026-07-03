import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/database/app_database.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  List<Promotion> _promos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final adminRepo = Provider.of<AdminRepository>(context, listen: false);
      final list = await adminRepo.getPromotions();
      if (mounted) {
        setState(() {
          _promos = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog({Promotion? promo}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = promo != null;
    final titleCtrl = TextEditingController(text: promo?.title);
    final descCtrl = TextEditingController(text: promo?.description);
    final codeCtrl = TextEditingController(text: promo?.code);
    final discountCtrl = TextEditingController(text: promo != null ? '${promo.discountPercentage}' : '');
    DateTime startDate = promo?.startDate ?? DateTime.now();
    DateTime endDate = promo?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark ? BorderSide(color: Colors.white.withOpacity(0.08)) : BorderSide.none,
          ),
          title: Text(
            isEdit ? 'Editar Promoción' : 'Nueva Promoción',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleCtrl, 'Título', Icons.title_rounded),
                const SizedBox(height: 10),
                _dialogField(descCtrl, 'Descripción (opcional)', Icons.description_rounded),
                const SizedBox(height: 10),
                _dialogField(codeCtrl, 'Código (ej: POTOSI20)', Icons.qr_code_rounded),
                const SizedBox(height: 10),
                _dialogField(discountCtrl, 'Descuento (%)', Icons.percent_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2030),
                          );
                          if (p != null) setDialogState(() => startDate = p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surface : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                          ),
                          child: Text(
                            'Inicio: ${AppDateUtils.formatDate(startDate.toIso8601String())}',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime(2030),
                          );
                          if (p != null) setDialogState(() => endDate = p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surface : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                          ),
                          child: Text(
                            'Fin: ${AppDateUtils.formatDate(endDate.toIso8601String())}',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || discountCtrl.text.isEmpty) return;
                try {
                  final adminRepo = Provider.of<AdminRepository>(context, listen: false);
                  if (isEdit) {
                    await adminRepo.updatePromotion(
                      promo.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim().toUpperCase() : null,
                      discountPercentage: double.tryParse(discountCtrl.text) ?? 0,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  } else {
                    await adminRepo.createPromotion(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim().toUpperCase() : null,
                      discountPercentage: double.tryParse(discountCtrl.text) ?? 0,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  }
                  Navigator.pop(ctx);
                  _loadPromos();
                  _showMessage(isEdit ? 'Promoción actualizada' : 'Promoción creada');
                } catch (e) {
                  _showMessage('Error al guardar promoción: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEdit ? 'Guardar' : 'Crear', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePromo(int id) async {
    try {
      final adminRepo = Provider.of<AdminRepository>(context, listen: false);
      await adminRepo.deletePromotion(id);
      _loadPromos();
      _showMessage('Promoción eliminada');
    } catch (e) {
      _showMessage('Error al eliminar: $e', isError: true);
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

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 16),
        filled: true,
        fillColor: isDark ? AppColors.surface : AppColors.cardLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Gestión de Promociones'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _loadPromos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nueva Promoción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promos.isEmpty
              ? Center(child: Text('No hay promociones', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)))
              : RefreshIndicator(
                  onRefresh: _loadPromos,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _promos.length,
                    itemBuilder: (ctx, i) {
                      final promo = _promos[i];
                      final isActive = promo.isActive;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(promo.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              if (promo.code != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(promo.code!, style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'Descuento: ${promo.discountPercentage}% • Válido hasta: ${AppDateUtils.formatDate(promo.endDate.toIso8601String())}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showCreateDialog(promo: promo),
                                icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                              ),
                              IconButton(
                                onPressed: () => _deletePromo(promo.id),
                                icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
