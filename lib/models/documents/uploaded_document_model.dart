class UploadedDocumentModel {
  final String id;
  final String userId;
  final String documentType; // 'diet' or 'blood'
  final String fileName;
  final String? filePath;
  final String? fileUrl;
  final String
  status; // 'uploaded', 'verified', 'rejected', 'processed', 'error'
  final String? ocrText;
  final Map<String, dynamic>? parsedData;
  final Map<String, dynamic>? validationResult;
  final DateTime createdAt;
  final DateTime updatedAt;

  UploadedDocumentModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.fileName,
    this.filePath,
    this.fileUrl,
    required this.status,
    this.ocrText,
    this.parsedData,
    this.validationResult,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UploadedDocumentModel.fromJson(Map<String, dynamic> json) {
    return UploadedDocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String?,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String,
      ocrText: json['ocr_text'] as String?,
      parsedData: json['parsed_data'] as Map<String, dynamic>?,
      validationResult: json['validation_result'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'status': status,
      'ocr_text': ocrText,
      'parsed_data': parsedData,
      'validation_result': validationResult,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
