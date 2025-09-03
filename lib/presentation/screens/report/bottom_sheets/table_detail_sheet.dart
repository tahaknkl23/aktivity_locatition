// lib/presentation/widgets/report/bottom_sheets/table_detail_sheet.dart
import 'package:flutter/material.dart';
import '../utils/chart_utils.dart';

class TableDetailSheet {
  static void show(
    BuildContext context,
    Map<String, dynamic> item,
    int rowNumber,
    List<String> columns,
    Color avatarColor, // Yeni parametre
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ModernTableDetailContent(
        item: item,
        rowNumber: rowNumber,
        columns: columns,
        avatarColor: avatarColor, // Rengi aktar
      ),
    );
  }
}

class _ModernTableDetailContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final int rowNumber;
  final List<String> columns;
  final Color avatarColor; // Yeni field

  const _ModernTableDetailContent({
    required this.item,
    required this.rowNumber,
    required this.columns,
    required this.avatarColor, // Constructor'a ekle
  });

  @override
  Widget build(BuildContext context) {
    // Boş olmayan alanları filtrele
    final validFields = <MapEntry<String, dynamic>>[];

    for (String column in columns) {
      final value = item[column];
      if (value != null && value.toString().isNotEmpty && value.toString() != '-' && value.toString() != 'null') {
        validFields.add(MapEntry(column, value));
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Modern handle bar
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildModernHeader(),

          // Content
          Expanded(
            child: validFields.isEmpty ? _buildEmptyState() : _buildFieldsList(validFields),
          ),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Aynı renkte avatar badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor, // Kartın rengini kullan
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '#$rowNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detay Görünümü',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Satır $rowNumber bilgileri',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList(List<MapEntry<String, dynamic>> validFields) {
    return ListView.separated(
      padding: EdgeInsets.all(20),
      itemCount: validFields.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final field = validFields[index];
        return _buildModernFieldCard(field, index);
      },
    );
  }

  Widget _buildModernFieldCard(MapEntry<String, dynamic> field, int index) {
    final icon = _getFieldIcon(field.key);
    final isImportant = _isImportantField(field.key);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImportant ? Color(0xFF8B5CF6).withValues(alpha: 0.2) : Color(0xFFE5E7EB),
          width: isImportant ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isImportant ? Color(0xFF8B5CF6).withValues(alpha: 0.1) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isImportant ? Color(0xFF8B5CF6) : Color(0xFF6B7280),
            ),
          ),

          SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChartUtils.formatColumnName(field.key),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                SelectableText(
                  ChartUtils.formatCellValue(field.value),
                  style: TextStyle(
                    fontSize: isImportant ? 16 : 15,
                    color: isImportant ? Color(0xFF8B5CF6) : Color(0xFF1F2937),
                    fontWeight: isImportant ? FontWeight.w700 : FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.info_outline,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Veri Bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bu kayıtta gösterilecek bilgi yok',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: 20),
            label: Text('Kapat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: avatarColor, // Kartın rengini kullan
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String fieldName) {
    final field = fieldName.toLowerCase();

    if (field.contains('name') || field.contains('ad')) return Icons.person_rounded;
    if (field.contains('phone') || field.contains('tel')) return Icons.phone_rounded;
    if (field.contains('email') || field.contains('posta')) return Icons.email_rounded;
    if (field.contains('address') || field.contains('adres')) return Icons.location_on_rounded;
    if (field.contains('company') || field.contains('firma')) return Icons.business_rounded;
    if (field.contains('date') || field.contains('tarih')) return Icons.calendar_today_rounded;
    if (field.contains('id') || field.contains('no')) return Icons.tag_rounded;
    if (field.contains('amount') || field.contains('tutar')) return Icons.payments_rounded;
    if (field.contains('status') || field.contains('durum')) return Icons.info_rounded;

    return Icons.description_rounded;
  }

  bool _isImportantField(String fieldName) {
    final field = fieldName.toLowerCase();
    return field.contains('name') || field.contains('ad') || field.contains('title') || field.contains('amount') || field.contains('id');
  }
}
