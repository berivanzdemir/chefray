import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/documents/uploaded_document_model.dart';

class DocumentHistoryService {
  DocumentHistoryService._();
  static final DocumentHistoryService instance = DocumentHistoryService._();

  final _supabase = Supabase.instance.client;
  final String _tableName = 'user_documents';
  final String _bucketName = 'user-documents';

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Gets all documents for the current user, ordered by creation date descending
  Future<List<UploadedDocumentModel>> getUserDocuments() async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('No active user for getUserDocuments');
      return [];
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UploadedDocumentModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error getting user documents: $e');
      return [];
    }
  }

  /// Gets documents by specific type ('diet' or 'blood')
  Future<List<UploadedDocumentModel>> getDocumentsByType(String type) async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('No active user for getDocumentsByType');
      return [];
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', uid)
          .eq('document_type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UploadedDocumentModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error getting documents by type: $e');
      return [];
    }
  }

  /// Gets the latest verified or processed document of a given type
  Future<UploadedDocumentModel?> getLatestDocumentByType(String type) async {
    final uid = _userId;
    if (uid == null) return null;

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', uid)
          .eq('document_type', type)
          .inFilter('status', const ['verified', 'processed'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return UploadedDocumentModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting latest document by type: $e');
      return null;
    }
  }

  /// Gets a specific document by its ID
  Future<UploadedDocumentModel?> getDocumentById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return UploadedDocumentModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting document by ID: $e');
      return null;
    }
  }

  /// Saves or updates a document record
  Future<void> saveUploadedDocument(UploadedDocumentModel document) async {
    try {
      await _supabase.from(_tableName).upsert(document.toJson());
    } catch (e) {
      debugPrint('Error saving uploaded document: $e');
      throw Exception('Belge veritabanına kaydedilirken hata oluştu.');
    }
  }

  /// Deletes a document record and its associated file in storage
  Future<void> deleteDocument(String id) async {
    try {
      final doc = await getDocumentById(id);
      if (doc == null) return;

      // Delete from storage if path exists
      if (doc.filePath != null && doc.filePath!.isNotEmpty) {
        await _supabase.storage.from(_bucketName).remove([doc.filePath!]);
      }

      // Delete from DB
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting document: $e');
      throw Exception('Belge silinirken hata oluştu.');
    }
  }

  /// Creates a short-lived signed URL for a file path
  Future<String?> createSignedUrl(String filePath) async {
    try {
      final response = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(filePath, 60 * 60); // 1 hour valid
      return response;
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      return null;
    }
  }
}
