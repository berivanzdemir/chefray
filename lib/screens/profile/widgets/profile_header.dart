import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../providers/theme_provider.dart';

class ProfileHeader extends StatefulWidget {
  final String displayName;
  final String avatarInitial;
  final String? avatarUrl;
  final String goalText;
  final int streakDays;
  final VoidCallback onNotificationTap;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.avatarInitial,
    this.avatarUrl,
    required this.goalText,
    required this.streakDays,
    required this.onNotificationTap,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final file = File(pickedFile.path);
      final provider = context.read<UserProfileProvider>();
      final success = await provider.uploadProfilePicture(file);

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil fotoğrafı güncellendi.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Sol: Avatar ───────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.backgroundMint,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5),
                  image: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                    ? Text(
                        widget.avatarInitial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              if (_isUploading)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                  ),
                ),
              // Küçük Kamera İkonu
              Positioned(
                bottom: 0,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 10, color: Theme.of(context).colorScheme.surface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // ── Orta: İsim ve Hedef — Expanded ile tüm kalan alanı alır ──────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.displayName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'SF Pro Display',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  children: [
                    const TextSpan(
                      text: 'Hedef: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark),
                    ),
                    TextSpan(text: widget.goalText),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // ── Sağ: Seri Gün kartı + tema toggle + bildirim ─────────────────
        _StreakCard(streakDays: widget.streakDays),
        const SizedBox(width: 8),
        _ThemeToggleButton(),
        const SizedBox(width: 8),
        _NotificationButton(onTap: widget.onNotificationTap),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kompakt Seri Gün kartı
// ─────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streakDays;

  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.orange, size: 18),
          const SizedBox(height: 1),
          Text(
            '$streakDays',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1),
          ),
          Text(
            'Seri Gün',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tema toggle butonu — gerçek ThemeMode değişimi + kalıcı kayıt
// ─────────────────────────────────────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              themeProvider.isDarkMode
                  ? Icons.nightlight_round
                  : Icons.wb_sunny_rounded,
              size: 20,
              color: themeProvider.isDarkMode
                  ? Colors.amber.shade400
                  : AppColors.primaryDark,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bildirim butonu
// ─────────────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                color: Theme.of(context).colorScheme.onSurface, size: 26),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  '3',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
