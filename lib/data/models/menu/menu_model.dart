// lib/data/models/menu/menu_model.dart
import 'package:aktivity_location_app/data/services/api/api_client.dart';
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
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => MenuItem.fromJson(item))
          .toList(),
    );
  }

  // Getter'lar
  String get cleanTitle => title.replaceAll(RegExp(r'[\[\]]'), '');
  bool get hasChildren => items.isNotEmpty;
  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get isNavigable => hasUrl && !hasChildren;

  // İkon belirleme
  IconData get icon {
    final lowerTitle = cleanTitle.toLowerCase();
    
    if (lowerTitle.contains('firma')) return Icons.business;
    if (lowerTitle.contains('kişi')) return Icons.people;
    if (lowerTitle.contains('aktivite')) return Icons.assignment;
    if (lowerTitle.contains('masraf')) return Icons.receipt;
    if (lowerTitle.contains('tahsilat')) return Icons.payment;
    if (lowerTitle.contains('araç')) return Icons.directions_car;
    if (lowerTitle.contains('dosya')) return Icons.folder;
    if (lowerTitle.contains('rapor')) return Icons.analytics;
    if (lowerTitle.contains('ekle')) return Icons.add_circle;
    if (lowerTitle.contains('liste')) return Icons.list;
    
    return Icons.navigate_next;
  }

  // Renk belirleme
  Color get color {
    final lowerTitle = cleanTitle.toLowerCase();
    
    if (lowerTitle.contains('firma')) return Colors.blue;
    if (lowerTitle.contains('kişi')) return Colors.green;
    if (lowerTitle.contains('aktivite')) return Colors.orange;
    if (lowerTitle.contains('masraf')) return Colors.red;
    if (lowerTitle.contains('tahsilat')) return Colors.purple;
    if (lowerTitle.contains('araç')) return Colors.teal;
    if (lowerTitle.contains('dosya')) return Colors.amber;
    if (lowerTitle.contains('rapor')) return Colors.indigo;
    
    return Colors.grey;
  }
}

