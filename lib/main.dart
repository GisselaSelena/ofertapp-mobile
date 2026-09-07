import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// Paleta elegante: verde azulado profundo + acentos cálidos, sobre
// fondo claro y suave. Se centraliza aquí para que todas las
// pantallas hereden el mismo look sin repetir estilos.
const _colorPrimario = Color(0xFF0F766E); // teal profundo
const _colorAcento = Color(0xFFF59E0B); // ámbar cálido
const _colorFondo = Color(0xFFF7F7F5);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OfertApp',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colorPrimario,
          primary: _colorPrimario,
          secondary: _colorAcento,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _colorFondo,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: _colorFondo,
          foregroundColor: Color(0xFF1F2937),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          titleLarge: TextStyle(
              fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          bodyMedium: TextStyle(color: Color(0xFF4B5563), height: 1.4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorPrimario,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _colorPrimario,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _colorPrimario, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFECECE9)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
      routerConfig: router,
    );
  }
}
