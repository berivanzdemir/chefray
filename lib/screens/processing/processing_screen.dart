import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/mascot/ray_avatar.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/user_health_profile.dart';
import '../../repositories/user_health_profile_repository.dart';
import '../../services/analysis/full_analysis_orchestrator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/documents/uploaded_document_model.dart';
import '../../services/documents/document_history_service.dart';

class ProcessingScreen extends StatefulWidget {
  final Map<String, dynamic>? params;
  const ProcessingScreen({super.key, this.params});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  int _activeStep = 0;
  String _statusText = 'Analiz başlatılıyor...';
  String? _processingError;

  static const _steps = [
    _Step(Icons.menu_book_rounded, 'Diyet\nAnalizi'),
    _Step(Icons.bloodtype_rounded, 'Kan\nAnalizi'),
    _Step(Icons.psychology_rounded, 'Birlikte\nSentez'),
    _Step(Icons.search_rounded, 'Tarif\nTaraması'),
    _Step(Icons.verified_rounded, 'Öneriler\nHazır'),
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Start background processing
    _advanceSteps();
  }

  Future<void> _advanceSteps() async {
    try {
      // Step 0: Initialise
      setState(() {
        _activeStep = 0;
        _statusText = 'Analiz başlatılıyor...';
      });

      final dietAnalysis =
          widget.params?['dietAnalysis'] as DietAnalysisResult?;
      final dietFile = widget.params?['dietFile'] as File?;
      final dietValidationResult =
          widget.params?['dietValidationResult'] as DocumentValidationResult?;
      final bloodFile = widget.params?['bloodFile'] as File?;
      final bloodValidationResult =
          widget.params?['bloodValidationResult'] as DocumentValidationResult?;
      final previousBloodAnalysis =
          widget.params?['previousBloodAnalysis'] as BloodAnalysisResult?;

      if (dietAnalysis == null) {
        throw Exception('Diyet analizi bulunamadı.');
      }

      final profileRepo = UserHealthProfileRepository.instance;
      UserHealthProfile? userProfile = await profileRepo
          .getCurrentUserHealthProfile();
      userProfile ??= UserHealthProfile.empty();

      final orchestrator = FullAnalysisOrchestrator();
      final result = await orchestrator.runFullAnalysis(
        dietAnalysis: dietAnalysis,
        dietFile: dietFile,
        dietValidationResult: dietValidationResult,
        bloodFile: bloodFile,
        bloodValidationResult: bloodValidationResult,
        previousBloodAnalysis: previousBloodAnalysis,
        userProfile: userProfile,
        onProgress: (stepIndex, stepDescription) {
          if (mounted) {
            setState(() {
              _activeStep = stepIndex;
              _statusText = stepDescription;
            });
          }
        },
      );

      // Save to Supabase user_documents table
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        if (dietFile != null) {
          final fileName = 'diet_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '$userId/$fileName';
          try {
            await Supabase.instance.client.storage
                .from('user-documents')
                .upload(filePath, dietFile);
            final doc = UploadedDocumentModel(
              id: '',
              userId: userId,
              documentType: 'diet',
              fileName:
                  'Diyet Listesi - ${DateTime.now().toIso8601String().split('T').first}',
              filePath: filePath,
              status: 'verified',
              parsedData: result.dietAnalysis.toJson(),
              validationResult: dietValidationResult?.toJson(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await DocumentHistoryService.instance.saveUploadedDocument(doc);
          } catch (e) {
            debugPrint('Failed to save diet doc to Supabase: $e');
          }
        }

        if (bloodFile != null) {
          final fileName = 'blood_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '$userId/$fileName';
          try {
            await Supabase.instance.client.storage
                .from('user-documents')
                .upload(filePath, bloodFile);
            final doc = UploadedDocumentModel(
              id: '',
              userId: userId,
              documentType: 'blood',
              fileName:
                  'Kan Tahlili - ${DateTime.now().toIso8601String().split('T').first}',
              filePath: filePath,
              status: 'verified',
              parsedData: result.bloodAnalysis?.toJson(),
              validationResult: bloodValidationResult?.toJson(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await DocumentHistoryService.instance.saveUploadedDocument(doc);
          } catch (e) {
            debugPrint('Failed to save blood doc to Supabase: $e');
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        context.go(
          '/analysis',
          extra: {
            'dietAnalysisResult': result.dietAnalysis,
            'bloodAnalysisResult': result.bloodAnalysis,
            'combinedAnalysisResult': result.combinedAnalysis,
            'recommendedRecipes': result.recommendations,
            'userHealthProfile': result.userHealthProfile,
            'candidateRecipes': result.candidateRecipes,
          },
        );
      }
    } catch (e) {
      debugPrint('Navigating to AnalysisFailureScreen because: $e');
      setState(() {
        _processingError =
            'Diyet listen ve kan değerlerin birlikte değerlendirilemedi. Lütfen tekrar deneyiniz.';
      });
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F241E) : AppColors.background;
    final cardBg = isDark ? const Color(0xFF17332B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF3FFF9) : AppColors.textDark;
    final descColor = isDark ? const Color(0xFFB7CCC5) : AppColors.textMedium;
    final mockDocBg = isDark ? const Color(0xFF17332B) : Colors.grey.shade200;
    final mockBlurBg = isDark
        ? const Color(0xFF0F241E).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.3);

    if (_processingError != null) {
      return Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Analiz Tamamlanamadı',
                  style: AppTextStyles.h1.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                Text(
                  _processingError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _processingError = null;
                      });
                      _advanceSteps();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tekrar Dene',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.divider,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Ana Sayfaya Dön',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo
              const AppLogo(size: 48, showText: true),
              const SizedBox(height: 24),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Diyetin analiz ediliyor',
                    style: AppTextStyles.displayMedium.copyWith(
                      fontSize: 22,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Opacity(
                      opacity: 0.3 + _pulseCtrl.value * 0.7,
                      child: const Text('✨', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: descColor),
              ),
              const SizedBox(height: 28),

              // ── Scan Visual ──────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Blurred document placeholder
                      Container(
                        decoration: BoxDecoration(
                          color: mockDocBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _buildMockDocument(isDark),
                      ),
                      // Blur overlay
                      Container(
                        decoration: BoxDecoration(
                          color: mockBlurBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      // Scan line
                      AnimatedBuilder(
                        animation: _scanCtrl,
                        builder: (_, child) {
                          final y = _scanCtrl.value * 320;
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: y,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0),
                                    AppColors.primary.withValues(alpha: 0.8),
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                    AppColors.primary.withValues(alpha: 0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Center focus icon
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) => Opacity(
                            opacity: 0.5 + _pulseCtrl.value * 0.5,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const RayAvatar(
                                size: 56,
                                imagePath: 'assets/mascot/ray_default.png',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Steps Row ────────────────────────────────
              Row(
                children: List.generate(_steps.length, (i) {
                  final active = i <= _activeStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark
                                      ? const Color(0xFF2B4A40)
                                      : AppColors.divider.withValues(
                                          alpha: 0.5,
                                        )),
                            borderRadius: BorderRadius.circular(14),
                            border: active
                                ? Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            _steps[i].icon,
                            size: 20,
                            color: active
                                ? AppColors.primary
                                : (isDark
                                      ? const Color(0xFFB7CCC5)
                                      : AppColors.textHint),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _steps[i].label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            color: active
                                ? AppColors.primary
                                : (isDark
                                      ? const Color(0xFFB7CCC5)
                                      : AppColors.textHint),
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // ── Security Card ────────────────────────────
              SoftCard(
                backgroundColor: cardBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verilerin Güvende',
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 14,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tüm verilerin gizli ve güvenli bir şekilde işlenir.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.primary.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Did-you-know Card ────────────────────────
              SoftCard(
                backgroundColor: cardBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biliyor muydun?',
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 14,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ChefRay, yapay zeka ile 50\'den fazla besin öğesini analiz eder.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🍊🥦🌿', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Mock blurred document content
  Widget _buildMockDocument(bool isDark) {
    final textColor = isDark ? const Color(0xFFB7CCC5) : Colors.grey.shade600;
    final skeletonColor = isDark
        ? const Color(0xFF2B4A40)
        : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pazartesi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            8,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Öğle Yemeği',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String label;
  const _Step(this.icon, this.label);
}
