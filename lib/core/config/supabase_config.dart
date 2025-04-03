import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    print('Loading environment variables...');
    await dotenv.load(fileName: ".env");
    
    // Use hardcoded values temporarily for debugging
    final url = "https://jqwzgfhcevsambdibuqo.supabase.co";
    final anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impxd3pnZmhjZXZzYW1iZGlidXFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2NDc3NTIsImV4cCI6MjA1OTIyMzc1Mn0.Gi_65LAmCbl_wT8nrXVlIppiBTAg4gRUDRPq4Du678k";
    
    print('Using hardcoded Supabase URL: $url');
    print('Using hardcoded Supabase Anon Key: ${anonKey.substring(0, 10)}...');
    
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