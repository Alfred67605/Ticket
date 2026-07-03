import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../../app/app_layout.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/app_text_field.dart';
import '../common/widgets/gradient_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _loginController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppLayout(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      if (mounted) {
        _showMessage(
          authProvider.errorMessage ?? AppStrings.errorCredentials,
          isError: true,
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isDark ? BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5) : BorderSide.none,
            ),
            title: Column(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 40),
                const SizedBox(height: 8),
                Text(
                  AppStrings.resetPassword,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ingresa tu correo y celular registrados para cambiar tu contraseña de inmediato.',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: emailCtrl,
                    label: AppStrings.email,
                    hint: 'correo@ejemplo.com',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: phoneCtrl,
                    label: AppStrings.phone,
                    hint: '70123456',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: passCtrl,
                    label: AppStrings.newPassword,
                    hint: '••••••••',
                    isPassword: true,
                    prefixIcon: Icons.lock_open_rounded,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isResetting
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final newPass = passCtrl.text;

                        if (email.isEmpty || phone.isEmpty || newPass.isEmpty) {
                          _showMessage('Por favor completa todos los campos', isError: true);
                          return;
                        }
                        if (newPass.length < 6) {
                          _showMessage('La contraseña debe tener mínimo 6 caracteres', isError: true);
                          return;
                        }

                        setDialogState(() => isResetting = true);
                        try {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final res = await authProvider.resetPassword(
                            email: email,
                            phone: phone,
                            newPassword: newPass,
                          );
                          if (res) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              _showMessage('Contraseña restablecida correctamente.');
                            }
                          } else {
                            if (mounted) {
                              _showMessage(authProvider.errorMessage ?? 'Error al restablecer.', isError: true);
                            }
                          }
                        } catch (e) {
                          _showMessage('Error al restablecer. Verifica tus datos de registro.', isError: true);
                        } finally {
                          setDialogState(() => isResetting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isResetting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Restablecer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      body: GradientBackground(
        child: Stack(
          children: [
            // Ambient glowing blobs in background (only in dark mode)
            if (isDark) ...[
              Positioned(
                top: 40,
                left: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
            ],

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Premium Logo Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                                width: 1.5,
                              ),
                              boxShadow: AppColors.primaryShadow(opacity: 0.3),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Inicia sesión en tu cuenta premium',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Glassmorphism login card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.card.withOpacity(0.45)
                                      : AppColors.surfaceLight.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.06),
                                    width: 1.5,
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        controller: _loginController,
                                        label: 'Email o Número de celular',
                                        hint: 'admin@ticketpotosi.com',
                                        prefixIcon: Icons.person_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Ingresa tu email o celular';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      AppTextField(
                                        controller: _passwordController,
                                        label: AppStrings.password,
                                        hint: '••••••••',
                                        isPassword: _obscurePassword,
                                        prefixIcon: Icons.lock_rounded,
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                                            size: 20,
                                          ),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                          if (v.length < 6) return 'Mínimo 6 caracteres';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _showForgotPasswordDialog,
                                          child: Text(
                                            AppStrings.forgotPassword,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      AppButton(
                                        text: 'Ingresar',
                                        onPressed: _login,
                                        isLoading: authProvider.isLoading,
                                        icon: Icons.login_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Demo admin card helper
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: AppColors.primaryLight,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Credenciales Demo Admin:',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'admin@ticketpotosi.com / admin',
                                        style: TextStyle(
                                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Registrarse option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.noAccount,
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  'Regístrate',
                                  style: TextStyle(
                                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
