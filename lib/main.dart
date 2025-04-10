import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Error initializing Supabase: $e');
    // You might want to show an error screen here
  }

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authState = ref.watch(authStateProvider);
        final isAuthenticated = authState.valueOrNull != null;
        final isAuthRoute = state.matchedLocation == '/auth';
        final isSignUpRoute = state.matchedLocation == '/signup';

        // Allow access to auth and signup pages when not authenticated
        if (!isAuthenticated && (isAuthRoute || isSignUpRoute)) {
          return null;
        }

        // Redirect to home if authenticated and trying to access auth/signup
        if (isAuthenticated && (isAuthRoute || isSignUpRoute)) {
          return '/';
        }

        // Redirect to auth if not authenticated and trying to access protected routes
        if (!isAuthenticated && !isAuthRoute && !isSignUpRoute) {
          return '/auth';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Outdoor',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
} 