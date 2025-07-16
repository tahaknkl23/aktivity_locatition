// Company List Models
class CompanyListResponse {
  final List<CompanyListItem> data;
  final int total;

  CompanyListResponse({
    required this.data,
    required this.total,
  });

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dataSourceResult = json['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final dataList = dataSourceResult['Data'] as List<dynamic>? ?? [];
      final total = dataSourceResult['Total'] as int? ?? 0;

      final companies = dataList.map((item) => CompanyListItem.fromJson(item as Map<String, dynamic>)).toList();

      return CompanyListResponse(
        data: companies,
        total: total,
      );
    } catch (e) {
      throw Exception('Company list parse error: $e');
    }
  }
}

class CompanyListItem {
  final int id;
  final String firma;
  final String telefon;
  final String webAdres;
  final String mail;
  final String kayitTarihi;
  final String sektor;
  final String temsilci;

  CompanyListItem({
    required this.id,
    required this.firma,
    required this.telefon,
    required this.webAdres,
    required this.mail,
    required this.kayitTarihi,
    required this.sektor,
    required this.temsilci,
  });

  factory CompanyListItem.fromJson(Map<String, dynamic> json) {
    return CompanyListItem(
      id: json['Id'] as int? ?? 0,
      firma: json['Firma'] as String? ?? '',
      telefon: json['Telefon'] as String? ?? '-',
      webAdres: json['WebAdres'] as String? ?? '-',
      mail: json['Mail'] as String? ?? '-',
      kayitTarihi: json['KayitTarihi'] as String? ?? '',
      sektor: json['Sektor'] as String? ?? '-',
      temsilci: json['Temsilci'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Firma': firma,
      'Telefon': telefon,
      'WebAdres': webAdres,
      'Mail': mail,
      'KayitTarihi': kayitTarihi,
      'Sektor': sektor,
      'Temsilci': temsilci,
    };
  }
}
