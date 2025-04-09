import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state changes
    ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'Outdoor Time',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          // Auth routes (unprotected)
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthPage(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignUpPage(),
          ),
          // Protected routes shell
          ShellRoute(
            builder: (context, state, child) {
              // This will be our scaffold for all protected routes
              return child;
            },
            routes: [
              // Home route
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          // Get the current user
          final user = ref.watch(currentUserProvider);
          
          // Handle deep links
          if (state.uri.toString().startsWith('io.supabase.outdoor://')) {
            if (state.uri.path == '/reset-password') {
              return '/auth';
            }
            if (state.uri.path == '/login-callback') {
              return '/';
            }
          }

          // If user is not authenticated and trying to access a protected route
          if (user == null) {
            // Allow access to auth and signup pages
            if (state.matchedLocation == '/auth' || state.matchedLocation == '/signup') {
              return null;
            }
            // Redirect to auth page for all other routes
            return '/auth';
          }

          // If user is authenticated and trying to access auth or signup pages
          if (user != null && (state.matchedLocation == '/auth' || state.matchedLocation == '/signup')) {
            return '/';
          }

          return null;
        },
      ),
    );
  }
} 