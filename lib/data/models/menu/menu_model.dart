import 'package:flutter/material.dart';

class MenuResponse {
  final List<MenuItem> menuItems;

  MenuResponse({required this.menuItems});

  factory MenuResponse.fromJson(List<dynamic> json) {
    return MenuResponse(
      menuItems: json.map((item) => MenuItem.fromJson(item)).toList(),
    );
  }
}

class MenuItem {
  final String title;
  final String? dashboard;
  final String? url;
  final int id;
  final List<MenuItem> items;

  MenuItem({
    required this.title,
    this.dashboard,
    this.url,
    required this.id,
    required this.items,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      title: json['title'] as String? ?? '',
      dashboard: json['dashboard'] as String?,
      url: json['url'] as String?,
      id: json['Id'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? []).map((item) => MenuItem.fromJson(item)).toList(),
    );
  }

  // Getter'lar
  String get cleanTitle => title.replaceAll(RegExp(r'[\[\]]'), '');
  bool get hasChildren => items.isNotEmpty;
  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get isNavigable => hasUrl && !hasChildren;

  // İkon belirleme - geliştirilmiş versiyon
  IconData get icon {
    final lowerTitle = cleanTitle.toLowerCase();

    // Ana menü ikonları
    if (lowerTitle.contains('firma')) return Icons.business_center;
    if (lowerTitle.contains('kişi')) return Icons.people_alt;
    if (lowerTitle.contains('aktivite')) return Icons.task_alt;
    if (lowerTitle.contains('fırsat')) return Icons.lightbulb_outline;
    if (lowerTitle.contains('numune')) return Icons.science_outlined;
    if (lowerTitle.contains('teklif')) return Icons.description;
    if (lowerTitle.contains('sözleşme')) return Icons.assignment_turned_in;
    if (lowerTitle.contains('sipariş')) return Icons.shopping_cart;
    if (lowerTitle.contains('proje')) return Icons.engineering;
    if (lowerTitle.contains('stok')) return Icons.inventory;
    if (lowerTitle.contains('iletişim')) return Icons.contact_support;
    if (lowerTitle.contains('özel talepler')) return Icons.star;
    if (lowerTitle.contains('dosya')) return Icons.folder;
    if (lowerTitle.contains('raporlar')) return Icons.analytics;
    if (lowerTitle.contains('diğer')) return Icons.more_horiz;
    if (lowerTitle.contains('ayarlar')) return Icons.settings;

    // Sub-menü ikonları - işlem türüne göre
    if (lowerTitle.contains('ekle')) return Icons.add_circle_outline;
    if (lowerTitle.contains('liste') || lowerTitle.contains('listele')) return Icons.list_alt;
    if (lowerTitle.contains('açık')) return Icons.lock_open;
    if (lowerTitle.contains('kapalı')) return Icons.lock;
    if (lowerTitle.contains('rapor')) return Icons.bar_chart;
    if (lowerTitle.contains('takvim')) return Icons.calendar_month;
    if (lowerTitle.contains('birleştir')) return Icons.merge;
    if (lowerTitle.contains('değiştir')) return Icons.edit;
    if (lowerTitle.contains('teklifler')) return Icons.receipt_long;
    if (lowerTitle.contains('notlar')) return Icons.note;
    if (lowerTitle.contains('özel')) return Icons.star_outline;
    if (lowerTitle.contains('ertelenmiş')) return Icons.schedule;
    if (lowerTitle.contains('iptal')) return Icons.cancel_outlined;
    if (lowerTitle.contains('alınan')) return Icons.download;
    if (lowerTitle.contains('verilen')) return Icons.upload;
    if (lowerTitle.contains('durum')) return Icons.info_outline;
    if (lowerTitle.contains('hareket')) return Icons.swap_horiz;
    if (lowerTitle.contains('barkod')) return Icons.qr_code;
    if (lowerTitle.contains('virman')) return Icons.transform;
    if (lowerTitle.contains('kampanya')) return Icons.campaign;
    if (lowerTitle.contains('talep')) return Icons.help_outline;
    if (lowerTitle.contains('öneri')) return Icons.lightbulb;
    if (lowerTitle.contains('şikayet')) return Icons.report_problem;
    if (lowerTitle.contains('haber') || lowerTitle.contains('duyuru')) return Icons.announcement;
    if (lowerTitle.contains('sıkça sorulan')) return Icons.quiz;
    if (lowerTitle.contains('kod')) return Icons.code;
    if (lowerTitle.contains('masraf')) return Icons.receipt;
    if (lowerTitle.contains('tahsilat')) return Icons.payment;
    if (lowerTitle.contains('araç')) return Icons.directions_car;

    // Varsayılan ikon
    return Icons.chevron_right;
  }

  // Renk belirleme - geliştirilmiş versiyon
  Color get color {
    final lowerTitle = cleanTitle.toLowerCase();

    // Ana menü renkleri
    if (lowerTitle.contains('firma')) return Colors.blue;
    if (lowerTitle.contains('kişi')) return Colors.green;
    if (lowerTitle.contains('aktivite')) return Colors.orange;
    if (lowerTitle.contains('fırsat')) return Colors.amber;
    if (lowerTitle.contains('numune')) return Colors.purple;
    if (lowerTitle.contains('teklif')) return Colors.indigo;
    if (lowerTitle.contains('sözleşme')) return Colors.teal;
    if (lowerTitle.contains('sipariş')) return Colors.brown;
    if (lowerTitle.contains('proje')) return Colors.deepOrange;
    if (lowerTitle.contains('stok')) return Colors.cyan;
    if (lowerTitle.contains('iletişim')) return Colors.pink;
    if (lowerTitle.contains('özel talepler')) return Colors.deepPurple;
    if (lowerTitle.contains('dosya')) return Colors.blueGrey;
    if (lowerTitle.contains('raporlar')) return Colors.indigo;
    if (lowerTitle.contains('diğer')) return Colors.grey;
    if (lowerTitle.contains('ayarlar')) return Colors.blueGrey;
    if (lowerTitle.contains('masraf')) return Colors.red;
    if (lowerTitle.contains('tahsilat')) return Colors.purple;
    if (lowerTitle.contains('araç')) return Colors.teal;

    // Sub-menü renkleri - işlem türüne göre
    if (lowerTitle.contains('ekle')) return Colors.green;
    if (lowerTitle.contains('liste') || lowerTitle.contains('listele')) return Colors.blue;
    if (lowerTitle.contains('açık')) return Colors.green;
    if (lowerTitle.contains('kapalı')) return Colors.red;
    if (lowerTitle.contains('ertelenmiş')) return Colors.orange;
    if (lowerTitle.contains('iptal')) return Colors.red;
    if (lowerTitle.contains('rapor')) return Colors.indigo;
    if (lowerTitle.contains('alınan')) return Colors.blue;
    if (lowerTitle.contains('verilen')) return Colors.orange;

    // Varsayılan renk
    return Colors.grey.shade600;
  }
}
