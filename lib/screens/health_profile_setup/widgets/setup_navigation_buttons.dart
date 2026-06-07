import 'package:flutter/material.dart';


/// Navigation buttons for the "Seni Tanıyalım" onboarding flow.
class SetupNavigationButtons extends StatelessWidget {
  final bool canGoBack;
  final bool isLastStep;
  final bool isValid;
  final bool isLoading;
  final bool isEditMode;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupNavigationButtons({
    super.key,
    this.isEditMode = false,
    required this.canGoBack,
    required this.isLastStep,
    required this.isValid,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (canGoBack) ...[
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : onBack,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8F3ED)),
                  ),
                  child: const Center(
                    child: Text(
                      'Geri',
                      style: TextStyle(
                        color: Color(0xFF102B2B),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            flex: canGoBack ? 1 : 1,
            child: GestureDetector(
              onTap: isLoading ? null : () {
                debugPrint('Health setup next pressed. Step: isValid=$isValid');
                onNext();
              },
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DFF88), Color(0xFF008F4C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF102B2B),
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastStep 
                                  ? (isEditMode ? 'Değişiklikleri Kaydet' : 'Profilimi Oluştur') 
                                  : 'Devam',
                              style: const TextStyle(
                                color: Color(0xFF102B2B),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (!isLastStep) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF102B2B),
                                size: 20,
                              ),
                            ],
                          ],
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
