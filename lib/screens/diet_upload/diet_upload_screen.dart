import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/soft_card.dart';
import '../../models/ai/analysis_results.dart';
import '../../services/ai/document_validation_service.dart';
import '../../services/ai/diet_analysis_service.dart';
import '../../services/ai/analysis_cache_manager.dart';
import '../../repositories/analysis/analysis_history_repository.dart';

enum UploadProcessState {
  idle,
  picking,
  selected,
  uploading,
  validating,
  validated,
  analyzing,
  failed
}

/// Two-mode upload screen: dietPdf → validates diet list → goes to blood upload
///                          bloodPdf → validates blood test → triggers combined analysis
class DietUploadScreen extends StatefulWidget {
  final String? uploadType;
  final DietAnalysisResult? previousDietAnalysis;
  final File? previousDietFile;

  const DietUploadScreen({
    super.key,
    this.uploadType,
    this.previousDietAnalysis,
    this.previousDietFile,
  });

  @override
  State<DietUploadScreen> createState() => _DietUploadScreenState();
}

class _DietUploadScreenState extends State<DietUploadScreen> {
  // ── Diet State Variables ──────────────────────────────────────────────────
  File? selectedDietFile;
  File? originalSelectedDietFile;
  File? previewDietFile;
  File? analysisDietFile;
  DocumentValidationResult? dietValidationResult;
  String? dietErrorMessage;
  String? selectedDietFileHash;

  // ── Blood State Variables ─────────────────────────────────────────────────
  File? selectedBloodFile;
  File? originalSelectedBloodFile;
  File? previewBloodFile;
  File? analysisBloodFile;
  DocumentValidationResult? bloodValidationResult;
  String? bloodErrorMessage;
  String? selectedBloodFileHash;

  UploadProcessState processState = UploadProcessState.idle;
  BloodAnalysisResult? selectedPreviousBloodAnalysis;
  bool isFetchingPreviousBlood = false;
  String? previousBloodSuccessMessage;

  @override
  void initState() {
    super.initState();
    if (widget.previousDietFile != null) {
      selectedDietFile = widget.previousDietFile;
      originalSelectedDietFile = widget.previousDietFile;
      previewDietFile = widget.previousDietFile;
      analysisDietFile = widget.previousDietFile;
    }
    if (widget.previousDietAnalysis != null) {
      dietValidationResult = const DocumentValidationResult(
        isValid: true,
        detectedType: 'diet_list',
        confidence: 1.0,
        extractedTextSummary: 'Önceden analiz edilmiş diyet.',
        reason: 'Passed from previous step.',
        userMessage: 'Diyet listesi doğrulandı.',
      );
    }
  }

  UploadType get _uploadType {
    final type = widget.uploadType?.toLowerCase() ?? '';
    if (['bloodpdf', 'blood_test', 'bloodtest', 'lab_result', 'laboratory_result', 'kan_tahlili', 'kan_degeri'].contains(type)) {
      return UploadType.bloodPdf;
    }
    return UploadType.dietPdf;
  }

  bool get _isBlood => _uploadType == UploadType.bloodPdf;

  // Getters & Setters delegating dynamically based on _isBlood
  File? get selectedFile => _isBlood ? selectedBloodFile : selectedDietFile;
  set selectedFile(File? val) {
    if (_isBlood) {
      selectedBloodFile = val;
    } else {
      selectedDietFile = val;
    }
  }

  File? get originalSelectedFile => _isBlood ? originalSelectedBloodFile : originalSelectedDietFile;
  set originalSelectedFile(File? val) {
    if (_isBlood) {
      originalSelectedBloodFile = val;
    } else {
      originalSelectedDietFile = val;
    }
  }

  File? get previewFile => _isBlood ? previewBloodFile : previewDietFile;
  set previewFile(File? val) {
    if (_isBlood) {
      previewBloodFile = val;
    } else {
      previewDietFile = val;
    }
  }

  File? get analysisFile => _isBlood ? analysisBloodFile : analysisDietFile;
  set analysisFile(File? val) {
    if (_isBlood) {
      analysisBloodFile = val;
    } else {
      analysisDietFile = val;
    }
  }

  DocumentValidationResult? get validationResult => _isBlood ? bloodValidationResult : dietValidationResult;
  set validationResult(DocumentValidationResult? val) {
    if (_isBlood) {
      bloodValidationResult = val;
    } else {
      dietValidationResult = val;
    }
  }

  String? get errorMessage => _isBlood ? bloodErrorMessage : dietErrorMessage;
  set errorMessage(String? val) {
    if (_isBlood) {
      bloodErrorMessage = val;
    } else {
      dietErrorMessage = val;
    }
  }

  String? get selectedFileHash => _isBlood ? selectedBloodFileHash : selectedDietFileHash;
  set selectedFileHash(String? val) {
    if (_isBlood) {
      selectedBloodFileHash = val;
    } else {
      selectedDietFileHash = val;
    }
  }



  String? get _selectedFileName {
    if (selectedFile != null) {
      return selectedFile!.path.split('/').last.split('\\').last;
    }
    if (selectedPreviousBloodAnalysis != null) {
      return "Önceki Kan Değerleri (Son Kayıt)";
    }
    return null;
  }

  // ── File Pickers ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      processState = UploadProcessState.picking;
      errorMessage = null;
    });
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2000,
        maxHeight: 2500,
      );
      if (picked != null && mounted) {
        await handleFileSelected(File(picked.path));
      } else {
        setState(() {
          processState = selectedFile != null
              ? UploadProcessState.validated
              : (selectedPreviousBloodAnalysis != null
                  ? UploadProcessState.validated
                  : UploadProcessState.idle);
        });
      }
    } catch (e) {
      setState(() {
        processState = UploadProcessState.failed;
        errorMessage = "Görsel seçilirken bir sorun oluştu. Lütfen tekrar deneyiniz.";
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      processState = UploadProcessState.picking;
      errorMessage = null;
    });
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && mounted) {
        final pf = result.files.single;
        if (pf.path != null) {
          await handleFileSelected(File(pf.path!));
        }
      } else {
        setState(() {
          processState = selectedFile != null
              ? UploadProcessState.validated
              : (selectedPreviousBloodAnalysis != null
                  ? UploadProcessState.validated
                  : UploadProcessState.idle);
        });
      }
    } catch (e) {
      setState(() {
        processState = UploadProcessState.failed;
        errorMessage = "Dosya seçilirken bir sorun oluştu. Lütfen tekrar deneyiniz.";
      });
    }
  }

  // ── Validation Flow ──────────────────────────────────────────────────────

  Future<void> handleFileSelected(File file) async {
    // 1. Clear previous state completely and set state to selected
    setState(() {
      selectedFile = file;
      originalSelectedFile = file;
      previewFile = file;
      analysisFile = null;
      validationResult = null;
      processState = UploadProcessState.selected;
      errorMessage = null;
      selectedPreviousBloodAnalysis = null;
      previousBloodSuccessMessage = null;
      selectedFileHash = null;
    });

    // 2. Short delay for the premium "selected" card to be visible
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      processState = UploadProcessState.validating;
    });

    try {
      if (!await file.exists()) {
        setState(() {
          errorMessage = "Dosya bulunamadı. Lütfen tekrar seçiniz.";
          processState = UploadProcessState.failed;
        });
        return;
      }
      
      final bytes = await file.readAsBytes();
      final size = bytes.length;
      if (size == 0) {
        setState(() {
          errorMessage = "Dosya okunamadı. Lütfen tekrar seçiniz.";
          processState = UploadProcessState.failed;
        });
        return;
      }

      // Check file extensions
      final ext = file.path.toLowerCase();
      if (!ext.endsWith('.jpg') && !ext.endsWith('.jpeg') && !ext.endsWith('.png') && !ext.endsWith('.pdf')) {
        setState(() {
          errorMessage = "Bu format desteklenmiyor. Lütfen JPG, PNG veya PDF yükleyiniz.";
          processState = UploadProcessState.failed;
        });
        return;
      }

      originalSelectedFile = file;

      // Copy to system temp directory with a highly unique timestamp-based filename to avoid picker cache collisions
      final tempDir = Directory.systemTemp;
      final fileExtension = ext.split('.').last;
      final uniqueName = 'chef_ray_upload_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final copiedFile = await file.copy('${tempDir.path}/$uniqueName');
      
      previewFile = copiedFile;

      // Check dimensions if it's an image
      int width = 0;
      int height = 0;
      if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) {
        try {
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          width = fi.image.width;
          height = fi.image.height;
        } catch (e) {
          debugPrint('Could not read image dimensions: $e');
        }
      }

      // Quality Validation Threshold
      if ((ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) && 
          (width < 900 || height < 900)) {
        debugPrint('Warning: Image resolution is below 900px ($width x $height). Using original selected file as analysis file.');
        analysisFile = originalSelectedFile;
      } else {
        analysisFile = copiedFile;
      }

      final analysisBytes = await analysisFile!.readAsBytes();
      final hash = sha256.convert(analysisBytes).toString();

      debugPrint('Original file path: ${originalSelectedFile!.path}');
      debugPrint('Analysis file path: ${analysisFile!.path}');
      debugPrint('Analysis file size: ${analysisBytes.length}');
      debugPrint('Analysis image width: $width');
      debugPrint('Analysis image height: $height');
      debugPrint('Analysis file hash: $hash');

      final svc = DocumentValidationService();
      final result = await svc.validateDocument(
        file: analysisFile!,
        uploadType: _uploadType,
      );

      // Log Gemini raw validation response details
      debugPrint('Parsed detectedType: ${result.detectedType}');
      debugPrint('Parsed confidence: ${result.confidence}');
      debugPrint('Parsed reason: ${result.reason}');
      debugPrint('Selected file hash: $hash');

      if (!result.isValid) {
        setState(() {
          selectedFile = copiedFile;
          selectedFileHash = hash;
          validationResult = result;
          errorMessage = _isBlood
              ? "Bu dosya kan tahlili gibi görünmüyor. Lütfen kan değerlerinizi içeren belgeyi daha net şekilde yükleyiniz."
              : "Bu dosya diyet listesi gibi görünmüyor. Lütfen diyet listenizi daha net şekilde yükleyiniz.";
          processState = UploadProcessState.failed;
        });
        return;
      }

      setState(() {
        selectedFile = copiedFile;
        selectedFileHash = hash;
        validationResult = result;
        errorMessage = null; 
        processState = UploadProcessState.validated;
      });
    } catch (e, st) {
      debugPrint('Document validation failed');
      debugPrint('Upload type: $_uploadType');
      debugPrint('File path: ${file.path}');
      try {
        debugPrint('File size: ${await file.length()}');
      } catch (_) {}
      debugPrint('Technical error: $e');
      debugPrint('Stack trace: $st');
      setState(() {
        errorMessage = "Dosya formatı okunamadı veya analiz başarısız oldu. Lütfen daha net bir belge yükleyiniz.";
        processState = UploadProcessState.failed;
      });
    }
  }

  void _clearFile() {
    setState(() {
      selectedFile = null;
      originalSelectedFile = null;
      previewFile = null;
      analysisFile = null;
      validationResult = null;
      selectedPreviousBloodAnalysis = null;
      processState = UploadProcessState.idle;
      errorMessage = null;
      previousBloodSuccessMessage = null;
      selectedFileHash = null;
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _onContinue() async {
    final bool isDocValid = processState == UploadProcessState.validated;

    if (!isDocValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce uygun bir belge yükleyiniz.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedFile != null) {
      if (selectedFileHash == null || analysisFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hata: Seçilen dosya doğrulaması bulunamadı.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      debugPrint('Sending to Gemini file path: ${analysisFile!.path}');
      debugPrint('Sending to Gemini file hash: $selectedFileHash');
    }

    if (_isBlood) {
      final canAnalyze =
        selectedDietFile != null &&
        dietValidationResult?.isValid == true &&
        (
          selectedPreviousBloodAnalysis != null ||
          (
            selectedBloodFile != null &&
            bloodValidationResult?.isValid == true
          )
        );

      if (!canAnalyze) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen hem diyet listenizi hem de kan değerlerinizi yüklediğinizden emin olun.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => processState = UploadProcessState.analyzing);

    if (!_isBlood) {
      // Diet Mode → analyze diet → go to blood upload screen
      _showProcessingDialog('Diyet listeniz analiz ediliyor...');
      
      try {
        final hash = selectedFileHash!;
        final cacheManager = AnalysisCacheManager();
        
        DietAnalysisResult? cachedDiet = cacheManager.getDietAnalysis(hash);
        DietAnalysisResult dietResult;
        
        if (cachedDiet != null) {
          dietResult = cachedDiet;
        } else {
          dietResult = await DietAnalysisService().analyzeDietDocument(
            file: analysisFile!,
            validationResult: validationResult!,
          );
          cacheManager.cacheDietAnalysis(hash, dietResult);
        }
        
        if (!mounted) return;
        Navigator.of(context).pop(); // close dialog
        
        context.push(
          '/diet-upload?uploadType=bloodPdf',
          extra: {
            'dietAnalysis': dietResult,
            'dietFile': analysisFile,
          },
        );
      } catch (e, st) {
        debugPrint('Diet analysis failed');
        debugPrint('File path: ${analysisFile?.path}');
        debugPrint('Technical error: $e');
        debugPrint('Stack trace: $st');
        if (mounted) {
          Navigator.of(context).pop(); // close dialog
          setState(() {
            errorMessage = "Diyet analizi tamamlanamadı. Lütfen dosyanızı kontrol edip tekrar deneyiniz.";
          });
        }
      } finally {
        setState(() => processState = UploadProcessState.validated);
      }
    } else {
      // Blood Mode → proceed to processing screen with both analyses
      setState(() => processState = UploadProcessState.validated);
      context.push('/processing', extra: {
        'dietAnalysis': widget.previousDietAnalysis,
        'dietFile': selectedDietFile,
        'dietValidationResult': dietValidationResult,
        'bloodFile': selectedPreviousBloodAnalysis != null ? null : selectedBloodFile,
        'bloodValidationResult': selectedPreviousBloodAnalysis != null ? null : bloodValidationResult,
        'previousBloodAnalysis': selectedPreviousBloodAnalysis,
      });
    }
  }

  Future<void> _usePreviousBlood() async {
    setState(() {
      isFetchingPreviousBlood = true;
      processState = UploadProcessState.validating;
      errorMessage = null;
      previousBloodSuccessMessage = null;
      selectedFile = null;
      validationResult = null;
    });

    try {
      final historyRepo = AnalysisHistoryRepository.instance;
      final latestBlood = await historyRepo.getLatestBloodAnalysis();

      if (latestBlood != null && latestBlood.markers.isNotEmpty) {
        setState(() {
          selectedPreviousBloodAnalysis = latestBlood;
          previousBloodSuccessMessage = "Önceki kan değerlerin seçildi.";
          processState = UploadProcessState.validated;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Önceki kan değerleriniz başarıyla seçildi!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = "Daha önce kaydedilmiş kan tahliliniz bulunamadı.";
          processState = UploadProcessState.failed;
        });
      }
    } catch (e) {
      debugPrint('Error loading previous blood test markers: $e');
      setState(() {
        errorMessage = "Kan değerleri geçmişi alınırken bir sorun oluştu. Lütfen tekrar deneyiniz.";
        processState = UploadProcessState.failed;
      });
    } finally {
      setState(() {
        isFetchingPreviousBlood = false;
      });
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titleText = _isBlood ? 'Kan Değerlerini Yükle' : 'Diyetini Yükle';
    final subtitleText = _isBlood
        ? 'Kan tahlili PDF veya görselini yükle,\ntarif önerilerini daha doğru kişiselleştirelim.'
        : 'Diyet listesinin fotoğrafını çek veya dosya yükle,\nyapay zeka ile analiz edelim.';
    final actionLabel = _isBlood ? 'Birlikte Analiz Et' : 'İleri';
    final securityText = _isBlood
        ? 'Kan değerlerin gizli ve güvenli şekilde işlenir.'
        : 'Diyet listen gizli ve güvenli bir şekilde işlenir.';

    final bool isDocValid = processState == UploadProcessState.validated;
    final bool isInteractionDisabled =
        processState == UploadProcessState.picking ||
        processState == UploadProcessState.selected ||
        processState == UploadProcessState.validating ||
        processState == UploadProcessState.analyzing;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 24),
              Text(titleText, style: AppTextStyles.displayMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(subtitleText,
                  textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              _buildUploadCard(),
              if (isFetchingPreviousBlood) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Önceki kan değerlerin getiriliyor...', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              if ((errorMessage != null || validationResult != null || previousBloodSuccessMessage != null) && 
                  processState != UploadProcessState.failed) ...[
                const SizedBox(height: 12),
                _buildValidationBanner(),
              ],
              _buildDebugPanel(),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Fotoğraf Çek',
                trailingIcon: Icons.camera_alt_rounded,
                onPressed: isInteractionDisabled ? null : () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _OutlineBtn(
                icon: Icons.photo_library_rounded,
                label: 'Galeriden Seç',
                onTap: isInteractionDisabled ? () {} : () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              _OutlineBtn(
                icon: Icons.upload_file_rounded,
                label: 'PDF / Dosya Yükle',
                onTap: isInteractionDisabled ? () {} : _pickFile,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: actionLabel,
                trailingIcon: _isBlood
                    ? Icons.analytics_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: (isDocValid && !isInteractionDisabled) ? _onContinue : () {
                  if (!isInteractionDisabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen önce uygun bir belge yükleyiniz.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              if (_isBlood) ...[
                const SizedBox(height: 12),
                _OutlineBtn(
                  icon: Icons.history_rounded,
                  label: 'Önceki kan değerlerimi kullan',
                  onTap: isInteractionDisabled ? () {} : _usePreviousBlood,
                ),
              ],
              const SizedBox(height: 20),
              SoftCard(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verilerin Güvende',
                              style: AppTextStyles.h3.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(securityText, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_rounded,
                        color: AppColors.primary.withValues(alpha: 0.4), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTips(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text('Analiz süreci ortalama 10-20 saniye sürer.',
                      style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
        ),
        const Spacer(),
        const AppLogo(size: 36, showText: true),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Güvenli',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullScreenPreview() {
    if (previewFile == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _selectedFileName ?? 'Görsel Önizleme',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              previewFile!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    final bool isError = processState == UploadProcessState.failed;
    final bool isValid = processState == UploadProcessState.validated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.4)
              : isValid
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── STATE: PICKING ───────────────────────────────────────────────
          if (processState == UploadProcessState.picking) ...[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Belge seçiliyor...', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            const SizedBox(height: 6),
            Text('Lütfen bekleyiniz.', style: AppTextStyles.bodySmall),
          ]
          // ── STATE: SELECTED ──────────────────────────────────────────────
          else if (processState == UploadProcessState.selected) ...[
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Belgeniz yüklendi. Doğrulama başlatılıyor...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // ── STATE: VALIDATING ────────────────────────────────────────────
          else if (processState == UploadProcessState.validating) ...[
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            Column(
              children: [
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  _isBlood ? 'Kan değerleriniz doğrulanıyor...' : 'Diyet listeniz doğrulanıyor...',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text('Bu işlem birkaç saniye sürebilir.', style: AppTextStyles.bodySmall),
              ],
            ),
          ]
          // ── STATE: VALIDATED ─────────────────────────────────────────────
          else if (processState == UploadProcessState.validated) ...[
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              _isBlood ? 'Kan değerleriniz doğrulandı.' : 'Diyet listeniz doğrulandı.',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dosyayı Temizle',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ]
          // ── STATE: FAILED ────────────────────────────────────────────────
          else if (processState == UploadProcessState.failed) ...[
            const Icon(Icons.error_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Belge Doğrulanamadı',
              style: AppTextStyles.h3.copyWith(color: AppColors.error, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                errorMessage ?? (_isBlood
                    ? 'Bu dosya kan tahlili gibi görünmüyor. Lütfen kan değerlerinizi içeren belgeyi daha net şekilde yükleyiniz.'
                    : 'Bu dosya diyet listesi gibi görünmüyor. Lütfen diyet listenizi daha net şekilde yükleyiniz.'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dosyayı Temizle',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ]
          // ── STATE: IDLE ──────────────────────────────────────────────────
          else ...[
            SizedBox(
              width: 80, height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.description_rounded,
                        size: 32, color: AppColors.primary.withValues(alpha: 0.6)),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Fotoğraf çek veya dosya yükle', style: AppTextStyles.h3.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text('JPG, PNG, PDF formatları desteklenir.', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePreviewSection() {
    if (selectedPreviousBloodAnalysis != null) {
      return Text(
        'Önceki Kan Değerleri Seçildi',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      );
    }
    if (selectedFile == null) return const SizedBox.shrink();

    final bool isPdf = _selectedFileName?.toLowerCase().endsWith('.pdf') ?? false;

    return Column(
      children: [
        if (!isPdf) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: _showFullScreenPreview,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.file(
                      previewFile ?? selectedFile!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 8, bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 32),
                const SizedBox(width: 12),
                Text('PDF Belgesi Yüklendi', style: AppTextStyles.h3.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          _selectedFileName ?? '',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium),
        ),
      ],
    );
  }

  Widget _buildValidationBanner() {
    final bool isError = errorMessage != null || (validationResult != null && !validationResult!.isValid);
    final String message = previousBloodSuccessMessage ?? errorMessage ?? validationResult?.userMessage ?? 'Bilinmeyen hata';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: isError ? AppColors.error : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: isError ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return const SizedBox.shrink();
  }


  Widget _buildTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daha iyi sonuçlar için ipuçları', style: AppTextStyles.h3.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 14),
        Row(
          children: [
            _TipCard(icon: Icons.fullscreen_rounded, text: 'Belgenin tamamı\ngörünsün'),
            const SizedBox(width: 10),
            _TipCard(icon: Icons.wb_sunny_rounded, text: 'Net ve aydınlık\nçekim yap'),
            const SizedBox(width: 10),
            _TipCard(icon: Icons.text_fields_rounded, text: 'Yazılar okunabilir\nolsun'),
          ],
        ),
      ],
    );
  }
}

// ── Reusable Widgets ───────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
