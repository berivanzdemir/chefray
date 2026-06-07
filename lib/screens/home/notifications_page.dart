import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/constants/app_text_styles.dart';
import '../../services/fcm_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _dailyRemindersEnabled = false;
  bool _waterRemindersEnabled = false;
  bool _calorieRemindersEnabled = false;
  bool _proteinRemindersEnabled = false;
  bool _movementRemindersEnabled = false;
  bool _weightRemindersEnabled = false;
  bool _analysisRemindersEnabled = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadSwitchStates();
  }

  /// SharedPreferences'tan switch durumlarını yükle + izin kontrolü yap.
  Future<void> _loadSwitchStates() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await FcmService.instance.checkPermissionStatus();
    final hasPermission =
        status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;

    // Bildirim geçmişini yükle ve test kayıtlarını filtrele
    final historyList = prefs.getStringList('notification_history') ?? [];
    final filteredHistory = historyList
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .where((item) {
          if (item == null) return false;
          final title = (item['title'] as String?) ?? '';
          final body = (item['body'] as String?) ?? '';
          final type = (item['type'] as String?) ?? '';
          // Test kayıtlarını filtrele
          if (title.contains('Test') || 
              body.contains('(Test)') || 
              body.contains('Bildirim sistemi çalışıyor') ||
              type == 'Test') {
            return false;
          }
          return true;
        })
        .cast<Map<String, dynamic>>()
        .toList();

    if (mounted) {
      setState(() {
        _dailyRemindersEnabled =
            hasPermission && (prefs.getBool('daily_reminders') ?? false);
        _waterRemindersEnabled =
            hasPermission && (prefs.getBool('water_reminders') ?? false);
        _calorieRemindersEnabled =
            hasPermission && (prefs.getBool('calorie_reminders') ?? false);
        _proteinRemindersEnabled =
            hasPermission && (prefs.getBool('protein_reminders') ?? false);
        _movementRemindersEnabled =
            hasPermission && (prefs.getBool('movement_reminders') ?? false);
        _weightRemindersEnabled =
            hasPermission && (prefs.getBool('weight_reminders') ?? false);
        _analysisRemindersEnabled =
            hasPermission && (prefs.getBool('analysis_reminders') ?? false);
            
        _history = filteredHistory;
      });
    }
  }

  /// Switch açılınca izin iste; izin yoksa switch'i geri kapat.
  Future<void> _onSwitchChanged(
      String key, bool value, void Function(bool) setStateCallback) async {
    if (value) {
      // İzin kontrolü yap
      final status = await FcmService.instance.checkPermissionStatus();

      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        // İzin zaten var
        setStateCallback(true);
      } else {
        // İzin iste
        final token =
            await FcmService.instance.requestPermissionAndGetToken();
        if (token != null) {
          setStateCallback(true);
        } else {
          // İzin reddedildi — switch'i geri kapat
          debugPrint('⚠️ Bildirim izni reddedildi, switch kapalı kalacak.');
          setStateCallback(false);
        }
      }
    } else {
      setStateCallback(false);
    }

    // Tercihi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value && (await _isPermissionGranted()));
  }

  Future<bool> _isPermissionGranted() async {
    final status = await FcmService.instance.checkPermissionStatus();
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Geçmiş Bildirimler',
                style: AppTextStyles.h3.copyWith(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            _buildNotificationList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bildirim Ayarları',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile('Günlük Hatırlatmalar', _dailyRemindersEnabled, (val) {
            _onSwitchChanged('daily_reminders', val, (v) {
              if (mounted) setState(() => _dailyRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Su Hatırlatmaları', _waterRemindersEnabled, (val) {
            _onSwitchChanged('water_reminders', val, (v) {
              if (mounted) setState(() => _waterRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Öğün / Kalori Hatırlatmaları', _calorieRemindersEnabled, (val) {
            _onSwitchChanged('calorie_reminders', val, (v) {
              if (mounted) setState(() => _calorieRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Protein Hatırlatmaları', _proteinRemindersEnabled, (val) {
            _onSwitchChanged('protein_reminders', val, (v) {
              if (mounted) setState(() => _proteinRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Hareket Hatırlatmaları', _movementRemindersEnabled, (val) {
            _onSwitchChanged('movement_reminders', val, (v) {
              if (mounted) setState(() => _movementRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Haftalık Tartı Hatırlatması', _weightRemindersEnabled, (val) {
            _onSwitchChanged('weight_reminders', val, (v) {
              if (mounted) setState(() => _weightRemindersEnabled = v);
            });
          }),
          _buildSwitchTile('Analiz Bildirimleri', _analysisRemindersEnabled, (val) {
            _onSwitchChanged('analysis_reminders', val, (v) {
              if (mounted) setState(() => _analysisRemindersEnabled = v);
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          'Henüz bildirim geçmişi bulunmuyor.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _history.length,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _history[index];
        final bool isRead = item['isRead'] as bool? ?? true;
        final title = item['title'] as String? ?? 'Bildirim';
        final body = item['body'] as String? ?? '';
        final type = item['type'] as String? ?? '';
        final timeStr = item['time'] as String?;
        String timeDisplay = '';
        if (timeStr != null) {
          final dt = DateTime.parse(timeStr);
          timeDisplay = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
        
        IconData icon = _getNotificationIcon(title, type);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: isRead ? Border.all(color: Theme.of(context).dividerColor) : Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRead ? Theme.of(context).dividerColor.withValues(alpha: 0.1) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: isRead ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: isRead ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7) : Theme.of(context).colorScheme.primary,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isRead ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bildirim tipine göre ikon döndürür.
  IconData _getNotificationIcon(String title, String type) {
    // Önce type'a göre kontrol et
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'calorie_low':
      case 'calorie_high':
      case 'calorie':
      case 'snack':
      case 'meal':
        return Icons.fastfood;
      case 'protein_low':
      case 'protein_high':
        return Icons.egg_alt;
      case 'activity':
        return Icons.directions_walk;
      case 'weight':
        return Icons.monitor_weight;
      case 'analysis':
        return Icons.auto_awesome;
    }

    // Type yoksa title'a göre kontrol et
    if (title.contains('Su')) return Icons.water_drop;
    if (title.contains('Hareket')) return Icons.directions_walk;
    if (title.contains('Tartı')) return Icons.monitor_weight;
    if (title.contains('Protein')) return Icons.egg_alt;
    if (title.contains('Kalori')) return Icons.fastfood;
    if (title.contains('Analiz')) return Icons.auto_awesome;
    if (title.contains('Günlük') || title.contains('Özet') || title.contains('Öğün')) return Icons.fastfood;

    return Icons.notifications;
  }
}
