import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/features/auth/presentation/login_screen.dart';
import 'package:smartstyle/features/intake/presentation/batch_camera_screen.dart';
import 'package:smartstyle/features/intake/presentation/intake_hub_screen.dart';
import 'package:smartstyle/features/intake/presentation/intake_queue_screen.dart';
import 'package:smartstyle/features/intake/presentation/manual_intake_screen.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';
import 'package:smartstyle/features/wardrobe/presentation/item_detail_screen.dart';
import 'package:smartstyle/features/wardrobe/presentation/item_edit_screen.dart';
import 'package:smartstyle/features/recommendations/presentation/home_dashboard_screen.dart';
import 'package:smartstyle/features/analytics/presentation/analytics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile Placeholder'));
}

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checkroom), label: 'Closet'),
          NavigationDestination(icon: Icon(Icons.add_a_photo), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Invalidate any caches tied to the session whenever the signed-in user changes.
  ref.listen(authStateProvider, (prev, next) {
    final prevUser = prev?.value?.session?.user.id;
    final nextUser = next.value?.session?.user.id;
    if (prevUser != nextUser) {
      ref.invalidate(itemsProvider);
    }
  });

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState.value?.session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/closet/:id',
        builder: (context, state) => ItemDetailScreen(itemId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => ItemEditScreen(itemId: state.pathParameters['id']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (c, s) => const HomeDashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/closet', builder: (c, s) => const ClosetScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/add',
              builder: (c, s) => const IntakeHubScreen(),
              routes: [
                GoRoute(path: 'manual', builder: (c, s) => const ManualIntakeScreen()),
                GoRoute(path: 'batch', builder: (c, s) => const BatchCameraScreen()),
                GoRoute(path: 'queue', builder: (c, s) => const IntakeQueueScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});
