// Activity List Models
class ActivityListResponse {
  final List<ActivityListItem> data;
  final int total;

  ActivityListResponse({
    required this.data,
    required this.total,
  });

  factory ActivityListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dataSourceResult = json['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final dataList = dataSourceResult['Data'] as List<dynamic>? ?? [];
      final total = dataSourceResult['Total'] as int? ?? 0;

      final activities = dataList.map((item) => ActivityListItem.fromJson(item as Map<String, dynamic>)).toList();

      return ActivityListResponse(
        data: activities,
        total: total,
      );
    } catch (e) {
      throw Exception('Activity list parse error: $e');
    }
  }
}

class ActivityListItem {
  final int id;
  final String? tipi;
  final String? konu;
  final String? firma;
  final String? kisi;
  final String? baslangic;
  final String? temsilci;
  final String? detay;

  ActivityListItem({
    required this.id,
    this.tipi,
    this.konu,
    this.firma,
    this.kisi,
    this.baslangic,
    this.temsilci,
    this.detay,
  });

  factory ActivityListItem.fromJson(Map<String, dynamic> json) {
    return ActivityListItem(
      id: json['Id'] as int? ?? 0,
      tipi: json['Tipi'] as String?,
      konu: json['Konu'] as String?,
      firma: json['Firma'] as String?,
      kisi: json['Kisi'] as String?,
      baslangic: json['Baslangic'] as String?,
      temsilci: json['Temsilci'] as String?,
      detay: json['Detay'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Tipi': tipi,
      'Konu': konu,
      'Firma': firma,
      'Kisi': kisi,
      'Baslangic': baslangic,
      'Temsilci': temsilci,
      'Detay': detay,
    };
  }
}
