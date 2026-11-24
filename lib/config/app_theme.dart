import 'package:flutter/material.dart';

/// Paleta institucional VozUL
class AppColors {
  // Azul institucional
  static const Color primario = Color(0xFF1A5276);
  static const Color primarioEscuro = Color(0xFF123B53);
  static const Color primarioClaro = Color(0xFF2980B9);

  // Cinza
  static const Color cinza = Color(0xFF6C757D);
  static const Color cinzaClaro = Color(0xFFF5F6FA);
  static const Color cinzaBorda = Color(0xFFE0E3E7);

  // Verde (estados positivos)
  static const Color verde = Color(0xFF27AE60);
  static const Color verdeClaro = Color(0xFFD5F5E3);

  // Aviso
  static const Color amarelo = Color(0xFFF39C12);
  static const Color amareloClaro = Color(0xFFFEF5E7);

  // Erro
  static const Color vermelho = Color(0xFFE74C3C);
  static const Color vermelhoClaro = Color(0xFFFDEDEC);

  // Cores de status
  static const Color statusRecebida = Color(0xFFF39C12);
  static const Color statusEmAnalise = Color(0xFF2980B9);
  static const Color statusInvestigacao = Color(0xFF8E44AD);
  static const Color statusResolvida = Color(0xFF27AE60);
  static const Color statusEncerrada = Color(0xFF6C757D);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primario,
        primary: AppColors.primario,
        secondary: AppColors.primarioClaro,
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cinzaClaro,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primario,
          side: const BorderSide(color: AppColors.primario),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cinzaBorda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cinzaBorda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primario, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.vermelho),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.cinza),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarioClaro,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cinzaBorda,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cinzaClaro,
        selectedColor: AppColors.primarioClaro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
      ),
    );
  }
}