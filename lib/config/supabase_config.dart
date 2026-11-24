import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuração do Supabase para o VozUL
class SupabaseConfig {
  static const String url = 'https://egqgskjjointbgkncjtf.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVncWdza2pqb2ludGJna25janRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0NzU1MjksImV4cCI6MjEwNTA1MTUyOX0.C85oZ3dym7txGhnSpExjppCx-HfFyd0E_oeXXPkoKXc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}