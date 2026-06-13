import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/diet_upload/diet_upload_screen.dart';
import '../screens/processing/processing_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/recipe_list/recipe_list_screen.dart';
import '../screens/exploded_recipe/exploded_recipe_screen.dart';
import '../screens/recipe_detail/recipe_detail_screen.dart';
import '../screens/recipe_detail/recipe_show_screen.dart';
import '../screens/cooking_mode/cooking_mode_screen.dart';
import '../screens/completion/completion_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/health_profile/health_profile_screen.dart';
import '../screens/health_profile_setup/health_profile_setup_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/body_analysis/body_analysis_screen.dart';
import '../screens/product_scan/barcode_scan_screen.dart';
import '../screens/product_scan/product_analysis_screen.dart';
import '../models/product/product_model.dart';
import '../screens/diet/personal_diet_screen.dart';
import '../models/ai/analysis_results.dart';
import '../repositories/user_health_profile_repository.dart';
import '../models/recipe_model.dart';
import '../models/recipes/recommended_recipe_view_model.dart';
import '../screens/analysis/analysis_history_screen.dart';
import '../screens/analysis/analysis_history_detail_screen.dart';
import '../models/analysis/analysis_history_item.dart';
import '../screens/home/notifications_page.dart';
import '../screens/favorites/favorite_recipes_screen.dart';
import '../screens/ray_assistant/ray_assistant_screen.dart';

/// GoRouter configuration for ChefRay app flow:
/// Splash → Onboarding → Auth → Home
/// Home FAB → Diet Upload → Processing → Analysis
/// Analysis CTA → Recipe List → Exploded → Detail → Cooking → Completion
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _authRedirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fade(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/diet-upload',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DietUploadScreen(
            uploadType: state.uri.queryParameters['uploadType'],
            previousDietAnalysis: state.extra is DietAnalysisResult
                ? state.extra as DietAnalysisResult
                : (state.extra is Map<String, dynamic>
                      ? (state.extra as Map<String, dynamic>)['dietAnalysis']
                            as DietAnalysisResult?
                      : null),
            previousDietFile: state.extra is Map<String, dynamic>
                ? (state.extra as Map<String, dynamic>)['dietFile'] as File?
                : null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/documents',
        pageBuilder: (context, state) => _fade(state, const DocumentsScreen()),
      ),
      GoRoute(
        path: '/analysis-history',
        pageBuilder: (context, state) =>
            _fade(state, const AnalysisHistoryScreen()),
      ),
      GoRoute(
        path: '/analysis-history-detail',
        pageBuilder: (context, state) => _fade(
          state,
          AnalysisHistoryDetailScreen(
            historyItem: state.extra as AnalysisHistoryItem?,
          ),
        ),
      ),
      GoRoute(
        path: '/processing',
        pageBuilder: (context, state) => _fade(
          state,
          ProcessingScreen(params: state.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: '/analysis',
        pageBuilder: (context, state) => _fade(
          state,
          AnalysisScreen(analysisData: state.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: '/recipe-list',
        pageBuilder: (context, state) => _fade(
          state,
          RecipeListScreen(
            preloadedRecipes: state.extra is List
                ? (state.extra as List).whereType<RecipeModel>().toList()
                : null,
            recommendedRecipes: state.extra is List
                ? (state.extra as List)
                      .whereType<RecommendedRecipeViewModel>()
                      .toList()
                : null,
            initialMealType: state.uri.queryParameters['mealType'],
          ),
        ),
      ),
      GoRoute(
        path: '/exploded-recipe',
        pageBuilder: (context, state) => _fade(
          state,
          ExplodedRecipeScreen(recipe: state.extra as RecipeModel?),
        ),
      ),
      GoRoute(
        path: '/recipe-show',
        pageBuilder: (context, state) =>
            _fade(state, RecipeShowScreen(recipe: state.extra as RecipeModel?)),
      ),
      GoRoute(
        path: '/recipe-detail',
        pageBuilder: (context, state) => _fade(
          state,
          RecipeDetailScreen(recipe: state.extra as RecipeModel?),
        ),
      ),
      GoRoute(
        path: '/cooking-mode',
        pageBuilder: (context, state) {
          RecipeModel? recipe;
          double multiplier = 1.0;
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            recipe = map['recipe'] as RecipeModel?;
            multiplier = (map['servingMultiplier'] as num?)?.toDouble() ?? 1.0;
          } else if (state.extra is RecipeModel) {
            recipe = state.extra as RecipeModel?;
          }
          return _fade(
            state,
            CookingModeScreen(recipe: recipe, servingMultiplier: multiplier),
          );
        },
      ),
      GoRoute(
        path: '/completion',
        pageBuilder: (context, state) =>
            _fade(state, CompletionScreen(recipe: state.extra as RecipeModel?)),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fade(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/health-profile',
        pageBuilder: (context, state) =>
            _fade(state, const HealthProfileScreen()),
      ),
      GoRoute(
        path: '/health-profile-setup',
        pageBuilder: (context, state) =>
            _fade(state, const HealthProfileSetupScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) =>
            _fade(state, const ProfileEditScreen()),
      ),
      GoRoute(
        path: '/body-analysis',
        pageBuilder: (context, state) =>
            _fade(state, const BodyAnalysisScreen()),
      ),
      GoRoute(
        path: '/product-scan',
        pageBuilder: (context, state) =>
            _fade(state, const BarcodeScanScreen()),
      ),
      GoRoute(
        path: '/product-analysis',
        pageBuilder: (context, state) => _fade(
          state,
          ProductAnalysisScreen(product: state.extra as ProductModel?),
        ),
      ),
      GoRoute(
        path: '/personal-diet',
        pageBuilder: (context, state) =>
            _fade(state, const PersonalDietScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _fade(state, const NotificationsPage()),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) =>
            _fade(state, const FavoriteRecipesScreen()),
      ),
      GoRoute(
        path: '/ray-assistant',
        pageBuilder: (context, state) =>
            _fade(state, const RayAssistantScreen()),
      ),
    ],
  );

  static const _publicRoutes = [
    '/onboarding',
    '/auth',
    '/register',
    '/health-profile',
  ];

  static String? _authRedirect(BuildContext context, GoRouterState state) {
    final loc = state.uri.toString();
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final isPublic = _publicRoutes.contains(loc);

    // Splash screen is never redirected — it handles its own navigation.
    if (loc == '/') return null;

    // Health profile setup requires a session but is not a public route.
    if (loc == '/health-profile-setup') {
      return hasSession ? null : '/auth';
    }

    if (hasSession && isPublic) {
      // Check cached profile status so incomplete profiles go to setup.
      final profileDone =
          UserHealthProfileRepository.instance.cachedProfileSetupCompleted;
      if (profileDone == null) {
        // Not yet checked — let splash handle it.
        return '/';
      }
      return profileDone ? '/home' : '/health-profile-setup';
    }
    if (!hasSession && !isPublic) {
      return '/auth';
    }
    return null;
  }

  static CustomTransitionPage _fade(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
