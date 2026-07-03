import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/app_text_field.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showMessage('El nombre no puede estar vacío', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );

    if (success) {
      setState(() => _isEditingProfile = false);
      _showMessage(AppStrings.successUpdate);
    } else {
      _showMessage(authProvider.errorMessage ?? AppStrings.errorGeneric, isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (_currPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      _showMessage('Completa los campos de contraseña', isError: true);
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _showMessage('La nueva contraseña debe tener al menos 6 caracteres', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.changePassword(
      _currPassCtrl.text,
      _newPassCtrl.text,
    );

    if (success) {
      setState(() => _isChangingPassword = false);
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _showMessage('Contraseña actualizada correctamente');
    } else {
      _showMessage(authProvider.errorMessage ?? AppStrings.errorGeneric, isError: true);
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.card : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? BorderSide(color: Colors.white.withOpacity(0.08)) : BorderSide.none,
        ),
        title: Text(
          AppStrings.logout,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir?',
          style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (_) => false,
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User avatar header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.primaryShadow(opacity: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.roleId == 1 ? 'Administrador' : 'Cliente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings options (Theme, etc.)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                    title: const Text('Modo Oscuro'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile info card (editable)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detalles de la cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (!_isEditingProfile)
                          IconButton(
                            onPressed: () => setState(() => _isEditingProfile = true),
                            icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isEditingProfile) ...[
                      AppTextField(
                        controller: _nameCtrl,
                        label: AppStrings.name,
                        hint: 'Juan Pérez',
                        prefixIcon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: AppStrings.phone,
                        hint: '70000000',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Guardar',
                              onPressed: _saveProfile,
                              isLoading: authProvider.isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Cancelar',
                              isSecondary: true,
                              onPressed: () {
                                _loadProfileData();
                                setState(() => _isEditingProfile = false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildDetailRow('Nombre', user.name, Icons.person_rounded),
                      const Divider(height: 20),
                      _buildDetailRow('Email', user.email, Icons.email_rounded),
                      const Divider(height: 20),
                      _buildDetailRow('Celular', user.phone ?? 'No registrado', Icons.phone_rounded),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password update card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (!_isChangingPassword)
                          IconButton(
                            onPressed: () => setState(() => _isChangingPassword = true),
                            icon: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                          ),
                      ],
                    ),
                    if (_isChangingPassword) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _currPassCtrl,
                        label: 'Contraseña Actual',
                        isPassword: true,
                        prefixIcon: Icons.lock_rounded,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _newPassCtrl,
                        label: 'Nueva Contraseña',
                        isPassword: true,
                        prefixIcon: Icons.lock_open_rounded,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Actualizar Contraseña',
                              onPressed: _changePassword,
                              isLoading: authProvider.isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Cancelar',
                              isSecondary: true,
                              onPressed: () {
                                _currPassCtrl.clear();
                                _newPassCtrl.clear();
                                setState(() => _isChangingPassword = false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        const SizedBox(width: 12),
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
}
