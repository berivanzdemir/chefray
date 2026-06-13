import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/bottom_nav_bar.dart';

import '../../services/notification_service.dart';
import '../../services/smart_notification_service.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/daily_goals_model.dart';

// Modüler Widget'lar
import 'widgets/home_header.dart';
import '../../widgets/home/analysis_ready_card.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/hydration_card.dart';
import 'widgets/recipe_recommendations_section.dart';
import 'widgets/packaged_product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _navIndex = 0;
  bool _isLoadingLatest = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLatestAnalysis();
    _initNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService().getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Uygulama foreground'a döndüğünde akıllı bildirimleri kontrol et
      final provider = context.read<UserProfileProvider>();
      SmartNotificationService().checkSmartNotifications(
        goals: provider.todayGoals,
        healthProfile: provider.healthProfile,
      );
      _loadUnreadCount();
    }
  }

  Future<void> _initNotifications() async {
    final service = NotificationService();
    await service.init();
    await service.requestPermissions();

    // Uygulama açılışında veriler yüklendikten sonra karar motorunu çalıştır
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final provider = context.read<UserProfileProvider>();
        SmartNotificationService().checkSmartNotifications(
          goals: provider.todayGoals,
          healthProfile: provider.healthProfile,
        );
      }
    });
  }

  Future<void> _loadLatestAnalysis() async {
    if (mounted) {
      setState(() {
        _isLoadingLatest = false;
      });
    }
  }

  Future<void> _addWater(int amount) async {
    final provider = context.read<UserProfileProvider>();
    DailyGoals? goals = provider.todayGoals;

    if (goals != null) {
      final newConsumed = (goals.waterConsumed + amount).clamp(0.0, 99999.0);
      final updatedGoals = goals.copyWith(waterConsumed: newConsumed);
      await provider.updateDailyGoals(updatedGoals);
      SmartNotificationService().checkSmartNotifications(goals: updatedGoals);
    } else {
      // Create new with defaults
      final updatedGoals = DailyGoals(
        userId: Supabase.instance.client.auth.currentUser?.id ?? 'temp',
        targetDate: DateTime.now(),
        caloriesTarget: 2000,
        proteinTarget: 100,
        waterTarget: 2000,
        waterConsumed: amount.toDouble(),
        activityTarget: 60,
      );
      await provider.updateDailyGoals(updatedGoals);
      SmartNotificationService().checkSmartNotifications(goals: updatedGoals);
    }
  }

  String get _displayName {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata;
      if (meta != null && meta['full_name'] != null) {
        return (meta['full_name'] as String).split(' ').first;
      }
      return user?.email?.split('@').first ?? 'Kullanıcı';
    } catch (e) {
      return 'Kullanıcı';
    }
  }

  String get _avatarInitial {
    final first = _displayName;
    return first.isNotEmpty ? first[0].toUpperCase() : 'K';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Dekoratif Arka Plan
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Opacity(
                opacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.03
                    : 0.08,
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                    stops: const [0.4, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/background.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            ),

            Consumer<UserProfileProvider>(
              builder: (context, provider, child) {
                final goals = provider.todayGoals;
                final currentWaterMl = goals?.waterConsumed.toInt() ?? 0;
                final targetWaterMl = goals?.waterTarget.toInt() ?? 2500;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    top: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Üst karşılama alanı
                      HomeHeader(
                        displayName: _displayName,
                        avatarInitial: _avatarInitial,
                        unreadCount: _unreadCount,
                        onNotificationTap: () async {
                          await context.push('/notifications');
                          _loadUnreadCount();
                        },
                      ),
                      const SizedBox(height: 24),

                      // 2. Analiz durum kartı
                      if (_isLoadingLatest)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        AnalysisReadyCard(
                          isAnalysisReady: true,
                          onCreateDietPlan: () =>
                              context.push('/personal-diet'),
                          onUploadTap: () =>
                              context.push('/diet-upload?uploadType=dietPdf'),
                          onSummaryTap: () => context.push('/analysis-history'),
                        ),

                      const SizedBox(height: 28),

                      // 3. Hızlı İşlemler
                      const QuickActionsSection(),

                      const SizedBox(height: 22),

                      // 4. Su Tüketimi widget
                      HydrationCard(
                        currentMl: currentWaterMl,
                        targetMl: targetWaterMl,
                        onAddSmall: () => _addWater(250),
                        onAddLarge: () => _addWater(500),
                        onDecreaseSmall: () => _addWater(-250),
                        onDecreaseLarge: () => _addWater(-500),
                      ),

                      const SizedBox(height: 24),

                      // 5. Sana Özel Öneriler
                      const RecipeRecommendationsSection(),

                      const SizedBox(height: 22),

                      // 6. Paketli Ürün Analizi
                      const PackagedProductCard(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ray-assistant'),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/mascot/ray_thinking.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.smart_toy_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ChefRayBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            context.push('/analysis-history');
          } else if (i == 2) {
            _showFloatingMenu();
          } else if (i == 3) {
            context.push('/recipe-list');
          } else if (i == 4) {
            context.push('/profile');
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
    );
  }

  void _showFloatingMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _floatingMenuItem(
                      Icons.description_rounded,
                      'Diyet Yükleme Alanı',
                      () {
                        Navigator.pop(context);
                        context.push('/diet-upload?uploadType=dietPdf');
                      },
                    ),
                    _floatingMenuItem(
                      Icons.vaccines_rounded,
                      'Kan Tahlili Yükleme Alanı',
                      () {
                        Navigator.pop(context);
                        context.push('/diet-upload?uploadType=bloodPdf');
                      },
                    ),
                    _floatingMenuItem(
                      Icons.qr_code_scanner_rounded,
                      'Ürün Tara',
                      () {
                        Navigator.pop(context);
                        context.push('/product-scan');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  Widget _floatingMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
