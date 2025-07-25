// activity_list_model.dart - GÜNCELLENMIŞ VERSİYON
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
  final String? konu; // Konu alanı - JSON'da yok ama model için saklayalım
  final String? firma;
  final String? kisi;
  final String? sube; // 🆕 YENİ ALAN - Çok önemli!
  final String? konum; // 🆕 YENİ ALAN - Koordinat bilgisi!
  final String? baslangic;
  final String? bitis; // 🆕 YENİ ALAN
  final String? temsilci;
  final String? detay;

  // 🆕 YENİ EKLENEN ALANLAR (önceki koddan):
  final String? tarih; // Kayıt tarihi (opsiyonel)
  final String? olusturan; // Oluşturan kişi (opsiyonel)
  final String? aktiviteTipi; // Aktivite tipi metni (opsiyonel)

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
    this.sube, // 🆕 YENİ
    this.konum, // 🆕 YENİ - Koordinat
    this.baslangic,
    this.bitis, // 🆕 YENİ
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
    debugPrint('[ACTIVITY_ITEM] 🔍 Sube: ${json['Sube']}'); // 🆕 YENİ ALAN

    return ActivityListItem(
      // ✅ TEMEL ALANLAR (JSON'dan direkt gelir):
      id: json['Id'] ?? 0,
      tipi: json['Tipi']?.toString(),
      konu: json['Konu']?.toString(), // JSON'da yok ama model için
      firma: json['Firma']?.toString(),
      kisi: json['Kisi']?.toString(),
      sube: json['Sube']?.toString(), // 🆕 YENİ ALAN!
      konum: json['Konum']?.toString(), // 🆕 YENİ ALAN - Koordinat!
      baslangic: json['Baslangic']?.toString(),
      bitis: json['Bitis']?.toString(), // 🆕 YENİ ALAN!
      temsilci: json['Temsilci']?.toString(),
      detay: json['Detay']?.toString(),

      // ✅ OPSİYONEL ALANLAR (enrichment için):
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
      'Sube': sube, // 🆕 YENİ
      'Konum': konum, // 🆕 YENİ - Koordinat
      'Baslangic': baslangic,
      'Bitis': bitis, // 🆕 YENİ
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

// 🔄 DİĞER MODELLER AYNI KALACAK (CompanyAddress, CompanyAddressResponse vs.)
// Bu modelleri değiştirmiyoruz, sadece ActivityListItem'ı güncelledik.

/// Company Address Model (Adresler sekmesi için) - DEĞİŞMEDİ
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
