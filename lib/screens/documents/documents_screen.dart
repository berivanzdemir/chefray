import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/soft_card.dart';
import 'document_detail_screen.dart';
import '../../services/documents/document_history_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  bool _hasValidDietPlan = false;
  bool _hasValidBloodValues = false;

  bool get _canAnalyzeTogether => _hasValidDietPlan && _hasValidBloodValues;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final dietDoc = await DocumentHistoryService.instance
          .getLatestDocumentByType('diet');
      final bloodDoc = await DocumentHistoryService.instance
          .getLatestDocumentByType('blood');

      if (mounted) {
        setState(() {
          _hasValidDietPlan = dietDoc != null;
          _hasValidBloodValues = bloodDoc != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading state for documents: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDietTap() async {
    if (_hasValidDietPlan) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DocumentDetailScreen(documentType: 'diet'),
        ),
      );
    } else {
      await context.push('/diet-upload?uploadType=dietPdf');
    }
    _loadState(); // Refresh state after upload
  }

  void _onBloodTap() async {
    if (_hasValidBloodValues) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DocumentDetailScreen(documentType: 'blood'),
        ),
      );
    } else {
      await context.push('/diet-upload?uploadType=bloodPdf');
    }
    _loadState();
  }

  String get _dietStatusLabel {
    if (_hasValidDietPlan) return 'Yüklendi ve doğrulandı';
    return 'Yüklenmedi';
  }

  String get _bloodStatusLabel {
    if (_hasValidBloodValues) return 'Yüklendi ve doğrulandı';
    return 'Yüklenmedi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const AppLogo(size: 36, showText: true),
                  const Spacer(),
                  const SizedBox(width: 42), // Balance
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Belgelerim',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : !_hasValidDietPlan && !_hasValidBloodValues
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _DocumentCard(
                            title: 'Diyet Listesi',
                            statusLabel: _dietStatusLabel,
                            isLoaded: _hasValidDietPlan,
                            onTap: _onDietTap,
                          ),
                          const SizedBox(height: 16),
                          _DocumentCard(
                            title: 'Kan Tahlili',
                            statusLabel: _bloodStatusLabel,
                            isLoaded: _hasValidBloodValues,
                            onTap: _onBloodTap,
                          ),
                          const SizedBox(height: 32),

                          // "Birlikte Analiz Et" button with proper conditions
                          if (_canAnalyzeTogether)
                            PrimaryButton(
                              text: 'Birlikte Analiz Et',
                              trailingIcon: Icons.auto_awesome,
                              onPressed: () => context.push('/processing'),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _buildDisabledMessage(),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Conditions checklist
                          if (!_canAnalyzeTogether) _buildConditionsChecklist(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz yüklenmiş belgen yok.',
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Diyet listesi veya kan tahlili yükleyerek belgelerini burada görüntüleyebilirsin.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Diyet Yükle', onPressed: _onDietTap),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _onBloodTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Kan Tahlili Yükle',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildDisabledMessage() {
    if (!_hasValidDietPlan && !_hasValidBloodValues) {
      return 'Birlikte analiz için diyet listesi ve kan değeri belgesinin doğrulanmış olması gerekir.';
    }
    if (!_hasValidDietPlan) {
      return 'Birlikte analiz için diyet listenizi yüklemeniz gerekiyor.';
    }
    if (!_hasValidBloodValues) {
      return 'Birlikte analiz için kan değerlerinizi yüklemeniz gerekiyor.';
    }
    return 'Analiz için gerekli şartlar sağlanamadı.';
  }

  Widget _buildConditionsChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Birlikte analiz için gerekenler:',
            style: AppTextStyles.h3.copyWith(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _conditionItem(
            icon: _hasValidDietPlan
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: _hasValidDietPlan ? AppColors.primary : AppColors.textLight,
            text: 'Diyet listesi OCR ile okunmalı ve doğrulanmalı',
            done: _hasValidDietPlan,
          ),
          const SizedBox(height: 8),
          _conditionItem(
            icon: _hasValidBloodValues
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: _hasValidBloodValues
                ? AppColors.primary
                : AppColors.textLight,
            text: 'Kan değerleri OCR ile okunmalı ve doğrulanmalı',
            done: _hasValidBloodValues,
          ),
        ],
      ),
    );
  }

  Widget _conditionItem({
    required IconData icon,
    required Color color,
    required String text,
    required bool done,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: done
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: done ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String statusLabel;
  final bool isLoaded;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.statusLabel,
    required this.isLoaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLoaded
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.description_rounded,
              color: isLoaded ? AppColors.primary : AppColors.textMedium,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isLoaded ? AppColors.primary : AppColors.textLight,
                    fontWeight: isLoaded ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoaded
                    ? Theme.of(context).scaffoldBackgroundColor
                    : AppColors.primary,
                foregroundColor: isLoaded ? AppColors.primary : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                minimumSize: const Size(80, 36),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isLoaded ? 'Detay' : 'Yükle',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
