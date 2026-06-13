import 'package:flutter/material.dart';
import '../../../services/tts_service.dart';

class VoiceReadCard extends StatelessWidget {
  final TtsService ttsService;
  final String narrationText;

  const VoiceReadCard({
    super.key,
    required this.ttsService,
    required this.narrationText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate a static waveform
    final List<double> waveHeights = [
      4,
      8,
      12,
      6,
      20,
      14,
      8,
      24,
      16,
      10,
      20,
      30,
      22,
      12,
      16,
      8,
      24,
      30,
      18,
      12,
      6,
      14,
      20,
      28,
      16,
      10,
      8,
      22,
      14,
      6,
      12,
      18,
      24,
      12,
      8,
      16,
      20,
      10,
      4,
      4,
      8,
      12,
      6,
      20,
      14,
      8,
      24,
      16,
      10,
      20,
      30,
      22,
      12,
      16,
      8,
      24,
      30,
      18,
      12,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A31)
            : const Color(0xFFF1F8F4), // Very light mint / dark green
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2B4A40) : const Color(0xFFE2EFE7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D9B5E), // Solid Green
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ray sesli anlatıyor',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF3FFF9)
                            : const Color(0xFF1E293B), // Dark slate / light
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ttsService.state == TtsState.playing
                          ? 'Okunuyor...'
                          : (ttsService.state == TtsState.paused
                                ? 'Duraklatıldı'
                                : 'Dinlemek için tıklayın...'),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFDFFFEF)
                            : const Color(
                                0xFF0D9B5E,
                              ), // Solid Green / light green
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Row(
                children: [
                  if (ttsService.state == TtsState.idle)
                    _circleBtn(
                      context,
                      Icons.play_arrow_rounded,
                      () => ttsService.speak(narrationText),
                      isDark,
                    )
                  else if (ttsService.state == TtsState.playing)
                    _circleBtn(
                      context,
                      Icons.pause_rounded,
                      () => ttsService.pause(),
                      isDark,
                    )
                  else if (ttsService.state == TtsState.paused)
                    _circleBtn(
                      context,
                      Icons.play_arrow_rounded,
                      () => ttsService.resume(),
                      isDark,
                    ),

                  const SizedBox(width: 8),
                  _circleBtn(
                    context,
                    Icons.refresh_rounded,
                    () => ttsService.restart(narrationText),
                    isDark,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Waveform
          SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(waveHeights.length, (index) {
                final isActive = ttsService.state == TtsState.playing;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 3,
                  height: waveHeights[index] * 0.6, // scale down
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0D9B5E).withValues(alpha: 0.3)
                        : const Color(0xFF0D9B5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17332B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF2B4A40) : const Color(0xFFE2EFE7),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? const Color(0xFFF3FFF9) : const Color(0xFF1E293B),
          size: 18,
        ),
      ),
    );
  }
}
