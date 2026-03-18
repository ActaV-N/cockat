import 'env.dart';

/// Supabase configuration loaded via envied (compile-time)
class SupabaseConfig {
  static String get url => Env.supabaseUrl;
  static String get anonKey => Env.supabaseAnonKey;
}
