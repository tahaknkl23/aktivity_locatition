// activity_list_model.dart - TAM HALİ

// Activity List Models - Updated with Address Support
import 'package:flutter/material.dart';

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
// 🆕 YENİ EKLENEN ALANLAR:
  final String? tarih; // Kayıt tarihi
  final String? olusturan; // Oluşturan kişi
  final String? aktiviteTipi; // Aktivite tipi metni
  // 🆕 YENİ: Adres bilgileri
  final String? kisaAdres;
  final String? acikAdres;
  final String? il;
  final String? ilce;
  final String? ulke;
  final String? adresTipi;

  ActivityListItem({
    required this.id,
    this.tipi,
    this.konu,
    this.firma,
    this.kisi,
    this.baslangic,
    this.temsilci,
    this.detay,
    // 🆕 YENİ PARAMETRELER:
    this.tarih,
    this.olusturan,
    this.aktiviteTipi,
    // 🆕 YENİ: Adres parametreleri
    this.kisaAdres,
    this.acikAdres,
    this.il,
    this.ilce,
    this.ulke,
    this.adresTipi,
  });

  factory ActivityListItem.fromJson(Map<String, dynamic> json) {
    // 🔍 DEBUG: CompanyId'yi arayalım
    debugPrint('[ACTIVITY_ITEM] 🔍 All JSON fields: ${json.keys.toList()}');
    debugPrint('[ACTIVITY_ITEM] 🔍 CompanyId: ${json['CompanyId']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 Company_Id: ${json['Company_Id']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 FirmaId: ${json['FirmaId']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 Firma_Id: ${json['Firma_Id']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 SirketId: ${json['SirketId']}');

    // Tüm JSON'u yazdır
    debugPrint('[ACTIVITY_ITEM] 🔍 Full JSON: $json');

    return ActivityListItem(
      id: json['Id'] ?? 0,
      tipi: json['Tipi']?.toString(),
      konu: json['Konu']?.toString(),
      firma: json['Firma']?.toString(),
      kisi: json['Kisi']?.toString(),
      baslangic: json['Baslangic']?.toString(),
      temsilci: json['Temsilci']?.toString(),
      detay: json['Detay']?.toString(),

      // 🆕 YENİ JSON MAPPING:
      tarih: json['Tarih']?.toString(),
      olusturan: json['Olusturan']?.toString(),
      aktiviteTipi: json['AktiviteTipi']?.toString(),

      // Adres mapping
      kisaAdres: json['KisaAdres']?.toString(),
      acikAdres: json['AcikAdres']?.toString(),
      il: json['Il']?.toString(),
      ilce: json['Ilce']?.toString(),
      ulke: json['Ulke']?.toString(),
      adresTipi: json['AdresTipi']?.toString(),
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
      // 🆕 YENİ: Adres bilgileri
      'KisaAdres': kisaAdres,
      'AcikAdres': acikAdres,
      'Il': il,
      'Ilce': ilce,
      'Ulke': ulke,
      'AdresTipi': adresTipi,
    };
  }

  String get displayAktiviteTipi => aktiviteTipi ?? tipi ?? 'Belirtilmemiş';

  /// Gösterilecek ana adres metni (önce kısa adres, yoksa açık adres)
  String get displayAddress {
    if (kisaAdres != null && kisaAdres!.isNotEmpty) {
      return kisaAdres!;
    }
    if (acikAdres != null && acikAdres!.isNotEmpty) {
      return acikAdres!;
    }
    return 'Adres belirtilmemiş';
  }

  /// Tam adres metni (şehir/ilçe dahil)
  String get fullAddress {
    final parts = <String>[];

    if (acikAdres != null && acikAdres!.isNotEmpty) {
      parts.add(acikAdres!);
    }

    if (ilce != null && ilce!.isNotEmpty) {
      parts.add(ilce!);
    }

    if (il != null && il!.isNotEmpty) {
      parts.add(il!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Tam adres belirtilmemiş';
  }

  /// Adres var mı kontrolü
  bool get hasAddress => (kisaAdres != null && kisaAdres!.isNotEmpty) || (acikAdres != null && acikAdres!.isNotEmpty);

  /// Lokasyon mevcut mu kontrolü (il/ilçe bazında)
  bool get hasLocation => (il != null && il!.isNotEmpty) && (ilce != null && ilce!.isNotEmpty);
}

// 🆕 YENİ: Company Address Model (Adresler sekmesi için)
class CompanyAddress {
  final int id;
  final String? tipi;
  final String il;
  final String ilce;
  final String acikAdres;
  final String? ulke;
  final String? kisaAdres;

  CompanyAddress({
    required this.id,
    this.tipi,
    required this.il,
    required this.ilce,
    required this.acikAdres,
    this.ulke,
    this.kisaAdres,
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
      id: json['Id'] as int? ?? 0,
      tipi: json['Tipi'] as String?,
      il: json['Il'] as String? ?? '',
      ilce: json['Ilce'] as String? ?? '',
      acikAdres: json['AcikAdres'] as String? ?? '',
      ulke: json['Ulke'] as String?,
      kisaAdres: json['KisaAdres'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Tipi': tipi,
      'Il': il,
      'Ilce': ilce,
      'AcikAdres': acikAdres,
      'Ulke': ulke,
      'KisaAdres': kisaAdres,
    };
  }

  /// Gösterilecek adres metni
  String get displayAddress {
    if (kisaAdres != null && kisaAdres!.isNotEmpty) {
      return kisaAdres!;
    }
    return acikAdres;
  }

  /// Tam adres metni
  String get fullAddress {
    final parts = [acikAdres, ilce, il];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  /// Adres etiketi (tip + lokasyon)
  String get addressLabel {
    final typePrefix = tipi != null && tipi!.isNotEmpty ? '$tipi: ' : '';
    return '$typePrefix$displayAddress';
  }
}

// 🆕 YENİ: Company Address Response
class CompanyAddressResponse {
  final List<CompanyAddress> data;
  final int total;

  CompanyAddressResponse({
    required this.data,
    required this.total,
  });

  factory CompanyAddressResponse.fromJson(Map<String, dynamic> json) {
    try {
      // DataSourceResult içindeki Data array'ini al
      final dataSourceResult = json['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final dataList = dataSourceResult['Data'] as List<dynamic>? ?? [];
      final total = dataSourceResult['Total'] as int? ?? 0;

      final addresses = dataList.map((item) => CompanyAddress.fromJson(item as Map<String, dynamic>)).toList();

      return CompanyAddressResponse(
        data: addresses,
        total: total,
      );
    } catch (e) {
      throw Exception('Company address parse error: $e');
    }
  }
}
