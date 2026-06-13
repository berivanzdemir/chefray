import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/soft_card.dart';
import '../../models/documents/uploaded_document_model.dart';
import '../../services/documents/document_history_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentType; // 'diet' or 'blood'

  const DocumentDetailScreen({super.key, required this.documentType});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isLoading = true;
  List<UploadedDocumentModel> _documents = [];

  String get _title => widget.documentType == 'diet'
      ? 'Diyet Listesi Geçmişi'
      : 'Kan Tahlili Geçmişi';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await DocumentHistoryService.instance.getDocumentsByType(
      widget.documentType,
    );
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDoc(UploadedDocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Belgeyi Sil'),
        content: const Text(
          'Bu belgeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Siliniyor...')));
      await DocumentHistoryService.instance.deleteDocument(doc.id);
      _loadDocuments();
    }
  }

  void _viewDoc(UploadedDocumentModel doc) async {
    if (doc.filePath == null && doc.fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge dosyası görüntülenemiyor.')),
      );
      return;
    }

    // Attempt to open or show signed URL
    String? url = doc.fileUrl;
    if (url == null && doc.filePath != null) {
      url = await DocumentHistoryService.instance.createSignedUrl(
        doc.filePath!,
      );
    }

    if (url == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Belge url alınamadı.')));
      return;
    }

    // Since we don't have a built-in PDF viewer for network URLs implemented directly in this snippet,
    // we route to a generic webview or just show a message. For now we will show a dialog or launch url.
    // In a full app, you would use url_launcher or a pdf viewer.
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Görüntüle'),
          content: Text(
            'Dosya Linki:\n$url\n\nNot: Gerçek uygulamada in-app pdf viewer veya url_launcher ile açılır.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    }
  }

  void _analyzeDoc(UploadedDocumentModel doc) {
    if (doc.parsedData != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Analiz Verisi'),
          content: SingleChildScrollView(
            child: Text(doc.parsedData.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu belge için analiz verisi bulunamadı.'),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
      case 'processed':
        return Colors.green;
      case 'error':
      case 'rejected':
        return Colors.red;
      case 'uploaded':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Doğrulandı';
      case 'processed':
        return 'Analiz Edildi';
      case 'error':
        return 'Hata';
      case 'rejected':
        return 'Reddedildi';
      case 'uploaded':
        return 'Yüklendi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _documents.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocumentCard(doc);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz belge yüklemedin.',
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Diyet listesi veya kan tahlili yükleyerek belgelerini burada görüntüleyebilirsin.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final uploadType = widget.documentType == 'diet'
                    ? 'dietPdf'
                    : 'bloodPdf';
                await context.push('/diet-upload?uploadType=$uploadType');
                _loadDocuments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Belge Yükle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(UploadedDocumentModel doc) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final dateStr = dateFormat.format(doc.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.documentType == 'diet'
                        ? Icons.restaurant_menu
                        : Icons.bloodtype_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName,
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(doc.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(doc.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(doc.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(
                  icon: Icons.visibility_rounded,
                  label: 'Görüntüle',
                  color: Theme.of(context).colorScheme.onSurface,
                  onTap: () => _viewDoc(doc),
                ),
                _ActionBtn(
                  icon: Icons.analytics_rounded,
                  label: 'Analiz Et',
                  color: AppColors.primary,
                  onTap: () => _analyzeDoc(doc),
                ),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Sil',
                  color: AppColors.error,
                  onTap: () => _deleteDoc(doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
