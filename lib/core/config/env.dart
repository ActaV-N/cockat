import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'SUPABASE_SERVICE_KEY')
  static const String supabaseServiceKey = _Env.supabaseServiceKey;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID_IOS')
  static const String googleClientIdIos = _Env.googleClientIdIos;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID_WEB')
  static const String googleClientIdWeb = _Env.googleClientIdWeb;

  @EnviedField(varName: 'HIGGSFIELD_ID')
  static const String higgsfieldId = _Env.higgsfieldId;

  @EnviedField(varName: 'HIGGSFIELD_SECRET')
  static const String higgsfieldSecret = _Env.higgsfieldSecret;
}
