import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    print('Loading environment variables...');
    await dotenv.load(fileName: ".env");
    
    final url = supabaseUrl;
    final anonKey = supabaseAnonKey;
    
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('Supabase URL or Anon Key not found in environment variables');
    }
    
    print('Initializing Supabase with URL: $url');
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    print('Supabase initialized successfully');
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
} 