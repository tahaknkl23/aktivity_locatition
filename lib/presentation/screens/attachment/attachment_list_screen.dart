import 'package:aktivity_location_app/data/services/api/base_api_service.dart';
import 'package:flutter/material.dart';

class AttachmentListScreen extends StatefulWidget {
  final String title;
  final String specialName;
  final Map<String, dynamic> parameters;

  const AttachmentListScreen({
    super.key,
    required this.title,
    required this.specialName,
    required this.parameters,
  });

  @override
  State<AttachmentListScreen> createState() => _AttachmentListScreenState();
}

class _AttachmentListScreenState extends State<AttachmentListScreen> {
  final BaseApiService _apiService = BaseApiService();

  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[ATTACHMENT_LIST] Loading attachments...');
      debugPrint('[ATTACHMENT_LIST] Special name: ${widget.specialName}');
      debugPrint('[ATTACHMENT_LIST] Parameters: ${widget.parameters}');

      final response = await _apiService.getSpecialReport(
        specialName: widget.specialName,
        parameters: widget.parameters,
        page: 1,
        pageSize: 999999,
      );

      final dataList = response['data'] as List? ?? [];

      debugPrint('[ATTACHMENT_LIST] ✅ Loaded ${dataList.length} attachments');

      setState(() {
        _attachments = dataList.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ATTACHMENT_LIST] ❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('${widget.title} yükleniyor...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Hata oluştu: $_errorMessage'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttachments,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_attachments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Dosya bulunamadı'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final attachment = _attachments[index];
        return _buildAttachmentCard(attachment);
      },
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    final fileName = attachment['FileName'] as String? ?? 'Unknown File';
    final firma = attachment['Firma'] as String?;
    final temsilci = attachment['Temsilci'] as String?;
    final baslama = attachment['BaslamaTarihi'] as String?;
    final takipNo = attachment['TakipNo'] as String?;
    final durum = attachment['AktiviteDurum'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name with icon
            Row(
              children: [
                Icon(_getFileIcon(fileName), color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Grid info
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Firma', firma),
                ),
                Expanded(
                  child: _buildInfoColumn('Temsilci', temsilci),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Tarih', baslama != null ? _formatDate(baslama) : null),
                ),
                Expanded(
                  child: _buildInfoColumn('Durum', durum),
                ),
              ],
            ),

            // Takip No if available
            if (takipNo != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Takip: $takipNo',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value ?? '-',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      // "22.08.2025 00:13" formatından sadece tarih kısmını al
      return dateString.contains(' ') ? dateString.split(' ')[0] : dateString;
    } catch (e) {
      return dateString;
    }
  }
}
