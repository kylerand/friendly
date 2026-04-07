import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'design/theme.dart';
import 'design/theme_provider.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  HomeWidget.setAppGroupId('group.com.kylerand.friendly');
  await SupabaseService.initialize();

  // Non-critical services — don't block app startup
  try {
    await NotificationService.initialize();
    await NotificationService.rescheduleAll();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }
  try {
    await FcmService.initialize();
  } catch (e) {
    debugPrint('FCM init skipped: $e');
  }
  runApp(const ProviderScope(child: FriendlyApp()));
}

class FriendlyApp extends ConsumerWidget {
  const FriendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Friendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
