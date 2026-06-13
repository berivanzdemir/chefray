import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../widgets/common/notification_badge_icon.dart';

class ProfileHeader extends StatefulWidget {
  final String displayName;
  final String avatarInitial;
  final String? avatarUrl;
  final String goalText;
  final int streakDays;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.avatarInitial,
    this.avatarUrl,
    required this.goalText,
    required this.streakDays,
    this.unreadCount = 0,
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
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedFile == null) return;
      if (!mounted) return;

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
              content: Text('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bir hata oluştu.')));
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.backgroundMint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  image:
                      widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
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
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              if (_isUploading)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.surface,
                      strokeWidth: 2.5,
                    ),
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
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 11,
                    color: Theme.of(context).colorScheme.surface,
                  ),
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
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.displayName,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                maxLines: 2,
                softWrap: true,
                text: TextSpan(
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Hedef: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    TextSpan(text: widget.goalText),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // ── Sağ: Seri Gün kartı + tema toggle + bildirim ─────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StreakCard(streakDays: widget.streakDays),
            const SizedBox(width: 6),
            const _ThemeToggleButton(),
            const SizedBox(width: 6),
            NotificationBadgeIcon(
              unreadCount: widget.unreadCount,
              onTap: widget.onNotificationTap,
            ),
          ],
        ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(height: 1),
          Text(
            '$streakDays',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          Text(
            'Seri Gün',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            width: 44,
            height: 44,
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
