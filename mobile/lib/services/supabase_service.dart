import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static Session? get currentSession => client.auth.currentSession;
  static User? get currentUser => client.auth.currentUser;
  static String? get accessToken => currentSession?.accessToken;
}
