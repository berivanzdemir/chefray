import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase bağlantı sabitleri.
/// Değerler .env dosyasından okunur; doğrudan koda gömülmez.
abstract final class SupabaseConfig {
  static String get url =>
      dotenv.env['SUPABASE_URL'] ??
      (throw StateError('SUPABASE_URL .env dosyasında bulunamadı'));

  static String get anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      (throw StateError('SUPABASE_ANON_KEY .env dosyasında bulunamadı'));
}
