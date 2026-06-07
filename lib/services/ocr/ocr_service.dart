import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';

class OcrResult {
  final String rawText;
  final List<OcrTextBlock> blocks;
  final bool success;
  final String? error;

  const OcrResult({
    required this.rawText,
    this.blocks = const [],
    this.success = true,
    this.error,
  });

  factory OcrResult.failure(String error) => OcrResult(
        rawText: '',
        success: false,
        error: error,
      );

  bool get isEmpty => rawText.trim().isEmpty;
  String get lowerText => rawText.toLowerCase();
}

class OcrTextBlock {
  final String text;
  final Rect? boundingBox;
  const OcrTextBlock({required this.text, this.boundingBox});
}

class Rect {
  final double left;
  final double top;
  final double width;
  final double height;
  const Rect(this.left, this.top, this.width, this.height);
}

class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Runs OCR on an image file using Google ML Kit.
  Future<OcrResult> recognizeImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks
          .map((b) => OcrTextBlock(
                text: b.text,
                boundingBox: Rect(
                  b.boundingBox.left.toDouble(),
                  b.boundingBox.top.toDouble(),
                  b.boundingBox.width.toDouble(),
                  b.boundingBox.height.toDouble(),
                ),
              ))
          .toList();

      final rawText = recognizedText.text;

      debugPrint('OCR completed: ${rawText.length} chars extracted');
      debugPrint('OCR blocks: ${blocks.length}');

      if (rawText.trim().isEmpty) {
        return OcrResult.failure('OCR metin çıkaramadı. Belge okunabilir değil.');
      }

      return OcrResult(rawText: rawText, blocks: blocks);
    } catch (e) {
      debugPrint('OCR error: $e');
      return OcrResult.failure('OCR işlemi başarısız: $e');
    }
  }

  /// Converts the first page of a PDF to an image and runs OCR on it.
  Future<OcrResult> _extractPdfAsImage(File pdfFile) async {
    try {
      debugPrint('PDF to Image OCR started for: ${pdfFile.path}');
      final document = await PdfDocument.openFile(pdfFile.path);
      final page = await document.getPage(1);
      
      // Render at 2x scale for better OCR quality
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      
      if (pageImage == null) {
        await page.close();
        await document.close();
        return OcrResult.failure('PDF sayfası görsele çevrilemedi.');
      }
      
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(pageImage.bytes);
      
      await page.close();
      await document.close();
      
      debugPrint('PDF rendered to image, running ML Kit...');
      final result = await recognizeImage(tempFile);
      
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return result;
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      return OcrResult.failure('PDF metin çıkarma başarısız: $e');
    }
  }

  /// Smart OCR: For PDFs, converts to image and runs ML Kit.
  /// For images, uses ML Kit directly.
  Future<OcrResult> extractText(File file) async {
    final ext = file.path.toLowerCase();

    if (ext.endsWith('.pdf')) {
      return await _extractPdfAsImage(file);
    }

    // For images, use ML Kit
    return await recognizeImage(file);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
