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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EE), // Very light mint
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ray sesli anlatıyor',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ttsService.state == TtsState.playing 
                        ? 'Okunuyor...' 
                        : (ttsService.state == TtsState.paused ? 'Duraklatıldı' : 'Dinlemek için tıklayın...'),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Controls
              Row(
                children: [
                  if (ttsService.state == TtsState.idle)
                    _ttsBtn(context, Icons.play_arrow_rounded, 'Oku', () => ttsService.speak(narrationText))
                  else if (ttsService.state == TtsState.playing)
                    _ttsBtn(context, Icons.pause_rounded, 'Duraklat', () => ttsService.pause())
                  else if (ttsService.state == TtsState.paused)
                    _ttsBtn(context, Icons.play_arrow_rounded, 'Devam Et', () => ttsService.resume()),
                  
                  const SizedBox(width: 12),
                  _ttsBtn(context, Icons.refresh_rounded, 'Baştan', () => ttsService.restart(narrationText)),
                ],
              ),
            ],
          ),
          if (ttsService.state == TtsState.playing) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ttsBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
