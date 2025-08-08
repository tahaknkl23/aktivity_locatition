// activity_list_model.dart - FIXED VERSION FOR DIRECT RESPONSE
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
      debugPrint('[ACTIVITY_RESPONSE] 🔍 Parsing response...');
      debugPrint('[ACTIVITY_RESPONSE] 🔍 JSON keys: ${json.keys.toList()}');

      // 🎯 RESPONSE FORMAT DETECTION
      List<dynamic> dataList;
      int total;

      if (json.containsKey('DataSourceResult')) {
        // Company format: {"DataSourceResult": {"Data": [...], "Total": 123}}
        debugPrint('[ACTIVITY_RESPONSE] 📋 Using DataSourceResult format');
        final dataSourceResult = json['DataSourceResult'] as Map<String, dynamic>? ?? {};
        dataList = dataSourceResult['Data'] as List<dynamic>? ?? [];
        total = dataSourceResult['Total'] as int? ?? 0;
      } else if (json.containsKey('Data')) {
        // Activity format: {"Data": [...], "Total": 123, "Aggregates": {}}
        debugPrint('[ACTIVITY_RESPONSE] 📋 Using direct Data format');
        dataList = json['Data'] as List<dynamic>? ?? [];
        total = json['Total'] as int? ?? 0;

        // If Total is null, try counting from Data
        if (total == 0 && dataList.isNotEmpty) {
          total = dataList.length;
          debugPrint('[ACTIVITY_RESPONSE] 📊 Total calculated from data length: $total');
        }
      } else {
        debugPrint('[ACTIVITY_RESPONSE] ❌ Unknown response format');
        dataList = [];
        total = 0;
      }

      debugPrint('[ACTIVITY_RESPONSE] 📊 Found ${dataList.length} items, total: $total');

      final activities = dataList.map((item) {
        debugPrint('[ACTIVITY_RESPONSE] 🔍 Processing item: ${item['Id']} - ${item['Firma']}');
        return ActivityListItem.fromJson(item as Map<String, dynamic>);
      }).toList();

      debugPrint('[ACTIVITY_RESPONSE] ✅ Successfully parsed ${activities.length} activities');

      return ActivityListResponse(
        data: activities,
        total: total,
      );
    } catch (e, stackTrace) {
      debugPrint('[ACTIVITY_RESPONSE] ❌ Parse error: $e');
      debugPrint('[ACTIVITY_RESPONSE] ❌ Stack trace: $stackTrace');
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
  final String? sube; // 🆕 YENİ ALAN - Çok önemli!
  final String? konum; // 🆕 YENİ ALAN - Koordinat bilgisi!
  final String? baslangic;
  final String? bitis; // 🆕 YENİ ALAN
  final String? temsilci;
  final String? detay;

  // 🆕 YENİ EKLENEN ALANLAR:
  final String? tarih;
  final String? olusturan;
  final String? aktiviteTipi;

  // 🆕 ADRES BİLGİLERİ (enrichment için):
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
    this.sube,
    this.konum,
    this.baslangic,
    this.bitis,
    this.temsilci,
    this.detay,
    // Opsiyonel alanlar:
    this.tarih,
    this.olusturan,
    this.aktiviteTipi,
    // Adres bilgileri:
    this.kisaAdres,
    this.acikAdres,
    this.il,
    this.ilce,
    this.ulke,
    this.adresTipi,
  });

  factory ActivityListItem.fromJson(Map<String, dynamic> json) {
    // 🔍 DEBUG: JSON yapısını logla
    debugPrint('[ACTIVITY_ITEM] 🔍 Processing activity: ${json['Id']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 Firma: ${json['Firma']}');
    debugPrint('[ACTIVITY_ITEM] 🔍 Sube: ${json['Sube']}');

    return ActivityListItem(
      // ✅ TEMEL ALANLAR:
      id: json['Id'] ?? 0,
      tipi: json['Tipi']?.toString(),
      konu: json['Konu']?.toString(),
      firma: json['Firma']?.toString(),
      kisi: json['Kisi']?.toString(),
      sube: json['Sube']?.toString(), // 🆕 ÖNEMLİ!
      konum: json['Konum']?.toString(), // 🆕 Koordinat!
      baslangic: json['Baslangic']?.toString(),
      bitis: json['Bitis']?.toString(),
      temsilci: json['Temsilci']?.toString(),
      detay: json['Detay']?.toString(),

      // ✅ OPSİYONEL ALANLAR:
      tarih: json['Tarih']?.toString(),
      olusturan: json['Olusturan']?.toString(),
      aktiviteTipi: json['AktiviteTipi']?.toString(),

      // ✅ ADRES ALANLARI (enrichment ile gelir):
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
      'Sube': sube,
      'Konum': konum,
      'Baslangic': baslangic,
      'Bitis': bitis,
      'Temsilci': temsilci,
      'Detay': detay,
      // Adres bilgileri:
      'KisaAdres': kisaAdres,
      'AcikAdres': acikAdres,
      'Il': il,
      'Ilce': ilce,
      'Ulke': ulke,
      'AdresTipi': adresTipi,
    };
  }

  // ✅ GETTER METHODS:

  String get displayAktiviteTipi => aktiviteTipi ?? tipi ?? 'Belirtilmemiş';

  /// 🆕 Şube bilgisi getter
  String get displaySube => sube ?? 'Şube belirtilmemiş';

  /// Şube var mı kontrolü
  bool get hasSube => sube != null && sube!.isNotEmpty;

  /// 🆕 Koordinat bilgisi getter
  String get displayKonum => konum ?? 'Koordinat belirtilmemiş';

  /// Koordinat var mı kontrolü
  bool get hasKonum => konum != null && konum!.isNotEmpty;

  /// 🆕 Koordinatları parse et
  (double?, double?) get parsedCoordinates {
    if (!hasKonum) return (null, null);

    try {
      final parts = konum!.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        return (lat, lng);
      }
    } catch (e) {
      debugPrint('[ACTIVITY_ITEM] Koordinat parse error: $e');
    }
    return (null, null);
  }

  /// 🆕 Koordinat var ve geçerli mi?
  bool get hasValidCoordinates {
    final (lat, lng) = parsedCoordinates;
    return lat != null && lng != null;
  }

  /// Gösterilecek ana adres metni (önce kısa adres, yoksa açık adres)
  String get displayAddress {
    if (kisaAdres != null && kisaAdres!.isNotEmpty) {
      return kisaAdres!;
    }
    if (acikAdres != null && acikAdres!.isNotEmpty) {
      return acikAdres!;
    }
    // 🆕 Eğer adres enrichment yoksa şube göster
    if (hasSube) {
      return sube!;
    }
    return 'Adres belirtilmemiş';
  }

  /// Tam adres metni (şehir/ilçe dahil)
  String get fullAddress {
    final parts = <String>[];

    if (acikAdres != null && acikAdres!.isNotEmpty) {
      parts.add(acikAdres!);
    } else if (hasSube) {
      parts.add(sube!); // Fallback olarak şube
    }

    if (ilce != null && ilce!.isNotEmpty) {
      parts.add(ilce!);
    }

    if (il != null && il!.isNotEmpty) {
      parts.add(il!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Tam adres belirtilmemiş';
  }

  /// Adres var mı kontrolü (enrichment veya şube)
  bool get hasAddress => (kisaAdres != null && kisaAdres!.isNotEmpty) || (acikAdres != null && acikAdres!.isNotEmpty) || hasSube;

  /// Lokasyon mevcut mu kontrolü (il/ilçe bazında)
  bool get hasLocation => (il != null && il!.isNotEmpty) && (ilce != null && ilce!.isNotEmpty);

  /// 🆕 Bitiş tarihi var mı kontrolü
  bool get hasBitis => bitis != null && bitis!.isNotEmpty;

  /// 🆕 Zaman aralığı gösterimi
  String get timeRange {
    if (baslangic == null) return 'Tarih belirtilmemiş';

    if (hasBitis && bitis != baslangic) {
      return '$baslangic - $bitis';
    }

    return baslangic!;
  }
}

/// Company Address Model (önceden var olan) - DEĞİŞMEDİ
class CompanyAddress {
  final int id;
  final String? tipi;
  final String il;
  final String ilce;
  final String acikAdres;
  final String? ulke;
  final String? kisaAdres;
  double? lat, lng;
  String? koordinatStr;

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

  String get displayAddress {
    if (kisaAdres != null && kisaAdres!.isNotEmpty) {
      return kisaAdres!;
    }
    return acikAdres;
  }

  String get fullAddress {
    final parts = [acikAdres, ilce, il];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  String get addressLabel {
    final typePrefix = tipi != null && tipi!.isNotEmpty ? '$tipi: ' : '';
    return '$typePrefix$displayAddress';
  }
}

/// Company Address Response - DEĞİŞMEDİ
class CompanyAddressResponse {
  final List<CompanyAddress> data;
  final int total;

  CompanyAddressResponse({
    required this.data,
    required this.total,
  });

  factory CompanyAddressResponse.fromJson(Map<String, dynamic> json) {
    try {
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
