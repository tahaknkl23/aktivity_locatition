// lib/presentation/widgets/report/charts/enhanced_data_grid.dart
import 'package:flutter/material.dart';
import '../utils/chart_utils.dart';
import '../bottom_sheets/table_detail_sheet.dart';

class EnhancedDataGrid extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const EnhancedDataGrid({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ChartUtils.getDisplayColumns(data);

    if (columns.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(child: Text('Veri bulunamadı')),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toplam: ${data.length} kayıt',
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
        ),

        // Modern professional card list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (context, index) => Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF10B981).withValues(alpha: 0.8),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            itemBuilder: (context, index) {
              final item = data[index];

              // Avatar rengini burada hesapla
              final colors = [
                Color(0xFF10B981), // Yeşil
                Color(0xFF3B82F6), // Mavi
                Color(0xFFF59E0B), // Turuncu
                Color(0xFF8B5CF6), // Mor
                Color(0xFFEF4444), // Kırmızı
                Color(0xFF06B6D4), // Cyan
              ];
              final avatarColor = colors[index % colors.length];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => TableDetailSheet.show(
                    context,
                    item,
                    index + 1,
                    columns,
                    avatarColor, // Kartın rengini geçir
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildProfessionalCard(item, columns, index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> item, List<String> columns, int index) {
    // Boş olmayan alanları filtrele
    final validFields = <MapEntry<String, dynamic>>[];

    for (String column in columns) {
      final value = item[column];
      if (value != null && value.toString().isNotEmpty && value.toString() != '-' && value.toString() != 'null') {
        validFields.add(MapEntry(column, value));
      }
    }

    // ID alanını bul
    String? idValue;
    final idField = validFields.firstWhere(
      (field) => field.key.toLowerCase().contains('id') || field.key.toLowerCase().contains('no') || (field.value is num),
      orElse: () => MapEntry('', ''),
    );
    if (idField.key.isNotEmpty) {
      idValue = idField.value.toString();
    }

    // Ana başlık
    String mainTitle = 'Veri Yok';
    if (validFields.isNotEmpty) {
      final titleField = validFields.firstWhere(
        (field) => field.key.toLowerCase().contains('name') || field.key.toLowerCase().contains('title') || field.key.toLowerCase().contains('ad'),
        orElse: () => validFields.first,
      );
      mainTitle = ChartUtils.formatCellValue(titleField.value);
    }

    // Grid için alanları hazırla (ID hariç, maksimum 4 alan)
    final gridFields = validFields.where((field) => field.key != idField.key).take(4).toList();

    // Renk seçimi (6 renk döngüsü)
    final colors = [
      Color(0xFF10B981), // Yeşil
      Color(0xFF3B82F6), // Mavi
      Color(0xFFF59E0B), // Turuncu
      Color(0xFF8B5CF6), // Mor
      Color(0xFFEF4444), // Kırmızı
      Color(0xFF06B6D4), // Cyan
    ];

    final avatarColor = colors[index % colors.length];
    final initial = mainTitle.isNotEmpty ? mainTitle[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İnisyal Avatar - modern uygulamalarda standart
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SizedBox(width: 16),

        // İçerik
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık + ID satırı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      mainTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // ID - sağ üst köşede
                  if (idValue != null) ...[
                    SizedBox(width: 12),
                    Text(
                      'ID: $idValue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: avatarColor,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 8),

              // Alt bilgiler - 2x2 grid
              if (gridFields.isNotEmpty) _buildSimpleInfoGrid(gridFields),
            ],
          ),
        ),

        SizedBox(width: 8),

        // Chevron
        Icon(
          Icons.chevron_right,
          size: 20,
          color: Color(0xFFD1D5DB),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoGrid(List<MapEntry<String, dynamic>> fields) {
    final rows = <Widget>[];

    for (int i = 0; i < fields.length; i += 2) {
      final leftField = fields[i];
      final rightField = i + 1 < fields.length ? fields[i + 1] : null;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol sütun
              Expanded(
                child: _buildSimpleInfoItem(leftField),
              ),

              SizedBox(width: 16),

              // Sağ sütun
              Expanded(
                child: rightField != null ? _buildSimpleInfoItem(rightField) : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildSimpleInfoItem(MapEntry<String, dynamic> field) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: '${ChartUtils.formatColumnName(field.key)}: ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: ChartUtils.formatCellValue(field.value),
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
