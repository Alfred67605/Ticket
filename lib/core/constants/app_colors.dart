import 'package:flutter/material.dart';

/// Paleta de colores unificada de TicketPotosí.
/// Basada en el diseño premium de Alfred (Azul Celeste/Sky Blue).
class AppColors {
  AppColors._();

  // ─── Primarios ───────────────────────────────────────────────────────────
  static const primary      = Color(0xFF0284C7);
  static const primaryLight = Color(0xFF38BDF8);
  static const primaryDark  = Color(0xFF0369A1);

  // ─── Fondos (Dark Mode) ──────────────────────────────────────────────────
  static const bg          = Color(0xFF070C19);
  static const surface     = Color(0xFF111A30);
  static const card        = Color(0xFF18233C);
  static const cardBorder  = Color(0xFF243258);

  // ─── Fondos (Light Mode) ─────────────────────────────────────────────────
  static const bgLight        = Color(0xFFF8FAFC);
  static const surfaceLight   = Color(0xFFFFFFFF);
  static const cardLight      = Color(0xFFF1F5F9);
  static const cardBorderLight = Color(0xFFE2E8F0);

  // ─── Textos ──────────────────────────────────────────────────────────────
  static const textPrimary   = Colors.white;
  static const textSecondary = Color(0xFF9EABB9);
  static const textMuted     = Color(0xFF5C6B8D);

  static const textPrimaryLight   = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textMutedLight     = Color(0xFF94A3B8);

  // ─── Semánticos ──────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);

  // ─── Gradientes ──────────────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgGradient = RadialGradient(
    center: Alignment.topRight,
    radius: 1.8,
    colors: [Color(0xFF0F1E36), bg],
  );

  // ─── Sombras ─────────────────────────────────────────────────────────────
  static List<BoxShadow> primaryShadow({double opacity = 0.4}) => [
    BoxShadow(
      color: primary.withValues(alpha: opacity),
      blurRadius: 40,
      spreadRadius: 2,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
