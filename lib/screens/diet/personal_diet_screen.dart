import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/soft_card.dart';
import '../../services/documents/document_history_service.dart';

class PersonalDietScreen extends StatefulWidget {
  const PersonalDietScreen({super.key});

  @override
  State<PersonalDietScreen> createState() => _PersonalDietScreenState();
}

class _PersonalDietScreenState extends State<PersonalDietScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _generateDynamicDiet();
  }

  Future<void> _generateDynamicDiet() async {
    try {
      final docService = DocumentHistoryService.instance;
      final bloodDoc = await docService.getLatestDocumentByType('blood');

      bool hasHighLdl = false;
      bool hasLowB12 = false;

      if (bloodDoc != null && bloodDoc.parsedData != null) {
        final markers = bloodDoc.parsedData!['markers'] as List?;
        if (markers != null) {
          for (var m in markers) {
            final name = m['name']?.toString().toLowerCase() ?? '';
            final status = m['status']?.toString().toLowerCase() ?? '';
            if (name.contains('ldl') && status.contains('high')) hasHighLdl = true;
            if (name.contains('b12') && status.contains('low')) hasLowB12 = true;
          }
        }
      }
      
      // Dinamik İçerik Üretimi
      List<String> breakfastItems = [
        hasHighLdl ? 'Yulaf ezmesi (Süt yerine badem sütü)' : '2 yumurtadan omlet (Az yağlı)',
        '1 dilim tam buğday ekmeği',
        hasLowB12 ? '30g peynir ve 1 adet yumurta' : 'Bol yeşillik ve domates',
      ];
      
      List<String> lunchItems = [
        hasHighLdl ? '150g ızgara somon' : '150g ızgara tavuk göğsü',
        '4 kaşık karabuğday pilavı',
        'Zeytinyağlı mevsim salata',
      ];

      List<String> dinnerItems = [
        '1 porsiyon zeytinyağlı sebze yemeği',
        hasLowB12 ? 'Etli kuru fasulye' : '1 kase yoğurt (Yarım yağlı)',
        '1 kase mercimek çorbası',
      ];

      if (mounted) {
        setState(() {
          _meals = [
            {
              'title': 'Kahvaltı',
              'time': '08:00 - 09:00',
              'icon': Icons.wb_sunny_rounded,
              'color': Colors.orange,
              'items': breakfastItems,
              'calories': hasHighLdl ? 280 : 320,
            },
            {
              'title': 'Öğle',
              'time': '13:00 - 14:00',
              'icon': Icons.lunch_dining_rounded,
              'color': Colors.red,
              'items': lunchItems,
              'calories': 450,
            },
            {
              'title': 'Ara Öğün',
              'time': '16:00 - 16:30',
              'icon': Icons.apple_rounded,
              'color': Colors.green,
              'items': [
                '1 adet yeşil elma',
                '10 adet çiğ badem',
                '1 fincan yeşil çay',
              ],
              'calories': 150,
            },
            {
              'title': 'Akşam',
              'time': '19:00 - 20:00',
              'icon': Icons.nights_stay_rounded,
              'color': Colors.indigo,
              'items': dinnerItems,
              'calories': 380,
            },
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _meals = _fallbackMeals();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _fallbackMeals() {
    return [
      {
        'title': 'Kahvaltı',
        'time': '08:00 - 09:00',
        'icon': Icons.wb_sunny_rounded,
        'color': Colors.orange,
        'items': ['Yumurta, Zeytin, Peynir', 'Tam buğday ekmeği'],
        'calories': 300,
      }
    ];
  }

  Future<void> _exportPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF hazırlanıyor...')),
    );

    try {
      final fontDataRegular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      final fontRegular = pw.Font.ttf(fontDataRegular);
      final fontBold = pw.Font.ttf(fontDataBold);

      final doc = pw.Document();
      
      // Modern Green Theme Colors
      final primaryColor = PdfColor.fromHex('#4CAF50');
      final textColor = PdfColor.fromHex('#333333');
      final bgColor = PdfColor.fromHex('#F9FBF9');

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ChefRay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Kisisel Diyet Listesi', style: pw.TextStyle(color: textColor, fontSize: 16)),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tarih: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Hazirlayan: ChefRay AI', style: pw.TextStyle(fontSize: 12, color: primaryColor)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              ..._meals.map((meal) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${meal['title']} (${meal['time']})', 
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textColor),
                          ),
                          pw.Text(
                            '${meal['calories']} kcal', 
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 8),
                      ...List<String>.from(meal['items']).map((item) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4, right: 6),
                                child: pw.Container(
                                  width: 4, height: 4,
                                  decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(item, style: pw.TextStyle(fontSize: 12, color: textColor)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF3CD'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'Not: Bu liste tamamen ChefRay yapay zeka analizine dayanir ve sadece tavsiye niteligindedir. Tibbi bir recete yerine gecmez.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#856404')),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'chefray_diyet_listesi.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF olusturulurken hata meydana geldi. Font dosyalari eksik olabilir.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    int totalCalories = _meals.fold(0, (sum, meal) => sum + (meal['calories'] as int));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kişisel Diyet Listem'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Date Selector
          _buildDateSelector(),
          const SizedBox(height: 16),
          
          // Meals List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MealCard(
                    title: meal['title'],
                    time: meal['time'],
                    icon: meal['icon'],
                    color: meal['color'],
                    items: List<String>.from(meal['items']),
                    calories: meal['calories'],
                  ),
                );
              },
            ),
          ),

          // Bottom Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Günlük Toplam:', style: AppTextStyles.h3.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      Text(
                        '$totalCalories kcal',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Listeyi PDF Olarak İndir',
                    trailingIcon: Icons.download_rounded,
                    onPressed: _exportPdf,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day;
          final dayName = _getDayName(date.weekday);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Pzt';
      case 2: return 'Sal';
      case 3: return 'Çar';
      case 4: return 'Per';
      case 5: return 'Cum';
      case 6: return 'Cmt';
      case 7: return 'Paz';
      default: return '';
    }
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final List<String> items;
  final int calories;

  const _MealCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    required this.items,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3.copyWith(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                    Text(time, style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                '$calories kcal',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
