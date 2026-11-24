import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/denuncia_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('pt_PT', null);
  } catch (e) {
    debugPrint('Erro ao inicializar formatos de data: $e');
  }

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Erro ao inicializar Supabase: $e');
  }

  runApp(const VozULApp());
}

class VozULApp extends StatelessWidget {
  const VozULApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DenunciaProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'VozUL',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}