// lib/data/models/attachment/attachment_file_model.dart - TEMİZLENMİŞ VERSİYON
import 'package:flutter/material.dart';

/// 📎 Ek dosya modeli - Web API response'una uygun
class AttachmentFile {
  final int id;
  final String fileName;
  final String localName;
  final int fileType; // 0: Image, 1: Document
  final String createdUserName;
  final String createdDate;
  final String formName;
  final int? tableId;
  final int? recordId;
  final int? formId;

  AttachmentFile({
    required this.id,
    required this.fileName,
    required this.localName,
    required this.fileType,
    required this.createdUserName,
    required this.createdDate,
    required this.formName,
    this.tableId,
    this.recordId,
    this.formId,
  });

  /// 🎯 GetFiles API response'u için (Data array içindeki objeler)
  factory AttachmentFile.fromJson(Map<String, dynamic> json) {
    return AttachmentFile(
      id: json['Id'] ?? 0,
      fileName: json['FileName'] ?? '',
      localName: json['LocalName'] ?? '',
      fileType: json['FileType'] ?? 0,
      createdUserName: json['CreatedUserName'] ?? '',
      createdDate: json['CreatedDate'] ?? '',
      formName: json['FormName'] ?? '',
      tableId: json['TableId'],
      recordId: json['RecordId'],
      formId: json['FormId'],
    );
  }

  /// 🎯 UploadFile API response'u için (Attachments array içindeki objeler)
  factory AttachmentFile.fromUploadResponse(Map<String, dynamic> json) {
    return AttachmentFile(
      id: json['Id'] ?? 0,
      fileName: json['FileName'] ?? '',
      localName: json['LocalName'] ?? '',
      fileType: json['FileType'] ?? 0,
      createdUserName: 'Current User', // Upload response'da CreatedUserName yok
      createdDate: json['CreatedDate'] ?? DateTime.now().toIso8601String(),
      formName: json['FormName'] ?? 'Aktivite',
      tableId: json['TableId'],
      recordId: json['RecordId'],
      formId: json['FormId'],
    );
  }

  /// 🎯 GetFiles liste response'u için (mobil uyumlu)
  factory AttachmentFile.fromListJson(Map<String, dynamic> json) {
    return AttachmentFile(
      id: json['Id'] ?? 0,
      fileName: json['FileName'] ?? '',
      localName: json['LocalName'] ?? '',
      fileType: json['FileType'] ?? 0,
      createdUserName: json['CreatedUserName'] ?? '',
      createdDate: json['CreatedDate'] ?? '',
      formName: json['FormName'] ?? '',
      tableId: json['TableId'],
      recordId: json['RecordId'],
      formId: json['FormId'],
    );
  }

  /// ✅ File type helpers
  bool get isImage => fileType == 0;
  bool get isDocument => fileType == 1;

  String get fileTypeText {
    switch (fileType) {
      case 0:
        return 'Resim';
      case 1:
        return 'Belge';
      default:
        return 'Dosya';
    }
  }

  /// 📱 Mobile için display formatı
  String get displayFileName {
    if (fileName.length > 30) {
      final extension = fileName.split('.').last;
      final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      return '${nameWithoutExt.substring(0, 25)}...$extension';
    }
    return fileName;
  }

  /// 📅 Tarih formatını düzenle
  String get formattedDate {
    try {
      final date = DateTime.parse(createdDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return createdDate;
    }
  }

  /// 🎨 Dosya tipi için renk
  Color get typeColor {
    switch (fileType) {
      case 0:
        return Colors.green; // Image
      case 1:
        return Colors.blue; // Document
      default:
        return Colors.grey;
    }
  }

  /// 🎯 Dosya tipi için icon
  IconData get typeIcon {
    switch (fileType) {
      case 0:
        return Icons.image;
      case 1:
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  /// 📋 JSON'a çevir
  Map<String, dynamic> toJson() => {
        'Id': id,
        'FileName': fileName,
        'LocalName': localName,
        'FileType': fileType,
        'CreatedUserName': createdUserName,
        'CreatedDate': createdDate,
        'FormName': formName,
        'TableId': tableId,
        'RecordId': recordId,
        'FormId': formId,
      };

  /// 🔍 Debug için
  @override
  String toString() {
    return 'AttachmentFile(id: $id, fileName: $fileName, fileType: $fileType)';
  }

  /// ⚖️ Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttachmentFile && other.id == id && other.localName == localName;
  }

  @override
  int get hashCode => Object.hash(id, localName);
}

/// 📤 Upload response modeli
class AttachmentUploadResponse {
  final bool status;
  final List<AttachmentFile> attachments;
  final String? errorMessage;

  AttachmentUploadResponse({
    required this.status,
    required this.attachments,
    this.errorMessage,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) {
    try {
      final status = json['Status'] as bool? ?? false;
      final attachmentsJson = json['Attachments'] as List<dynamic>? ?? [];

      final attachments = attachmentsJson.map((item) => AttachmentFile.fromUploadResponse(item as Map<String, dynamic>)).toList();

      return AttachmentUploadResponse(
        status: status,
        attachments: attachments,
        errorMessage: status ? null : 'Upload failed',
      );
    } catch (e) {
      debugPrint('[ATTACHMENT] Upload response parse error: $e');
      return AttachmentUploadResponse(
        status: false,
        attachments: [],
        errorMessage: 'Parse error: ${e.toString()}',
      );
    }
  }

  bool get isSuccess => status && attachments.isNotEmpty;
  AttachmentFile? get firstFile => attachments.isNotEmpty ? attachments.first : null;
}

/// 📁 Dosya listesi response modeli
class AttachmentFileListResponse {
  final List<AttachmentFile> data;
  final int total;
  final Map<String, dynamic>? aggregates;
  final List<String>? errors;

  AttachmentFileListResponse({
    required this.data,
    required this.total,
    this.aggregates,
    this.errors,
  });

  factory AttachmentFileListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dataList = json['Data'] as List<dynamic>? ?? [];
      final files = dataList.map((item) => AttachmentFile.fromJson(item as Map<String, dynamic>)).toList();

      return AttachmentFileListResponse(
        data: files,
        total: json['Total'] as int? ?? 0,
        aggregates: json['Aggregates'] as Map<String, dynamic>?,
        errors: (json['Errors'] as List<dynamic>?)?.cast<String>(),
      );
    } catch (e) {
      debugPrint('[ATTACHMENT] File list response parse error: $e');
      return AttachmentFileListResponse(
        data: [],
        total: 0,
      );
    }
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
}

/// 🗑️ Delete response modeli
class AttachmentDeleteResponse {
  final bool isSuccess;
  final String? message;

  AttachmentDeleteResponse({
    required this.isSuccess,
    this.message,
  });

  factory AttachmentDeleteResponse.fromJson(Map<String, dynamic> json) {
    try {
      // API'den gelen response formatına göre ayarla
      bool success = false;

      if (json.containsKey('Success')) {
        success = json['Success'] as bool? ?? false;
      } else if (json.containsKey('Status')) {
        success = json['Status'] as bool? ?? false;
      } else {
        // Eğer özel field yoksa, HTTP 200 = success kabul et
        success = true;
      }

      return AttachmentDeleteResponse(
        isSuccess: success,
        message: json['Message'] as String? ?? json['ErrorMessage'] as String?,
      );
    } catch (e) {
      debugPrint('[ATTACHMENT] Delete response parse error: $e');
      return AttachmentDeleteResponse(
        isSuccess: false,
        message: 'Parse error: ${e.toString()}',
      );
    }
  }
}

/// 📁 Dosya türü enum'u
enum AttachmentFileType {
  image(0, 'Resim', Icons.image, Colors.green),
  document(1, 'Belge', Icons.description, Colors.blue);

  const AttachmentFileType(this.value, this.label, this.icon, this.color);

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  static AttachmentFileType fromValue(int value) {
    return AttachmentFileType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AttachmentFileType.document,
    );
  }
}

/// 📎 Dosya servisi için exception sınıfı
class AttachmentException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AttachmentException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AttachmentException($code): $message';
    }
    return 'AttachmentException: $message';
  }
}

/// 📱 Mobile UI için helper extension'lar
extension AttachmentFileExtensions on AttachmentFile {
  /// Preview için uygun mu?
  bool get canPreview => isImage;

  /// Download için uygun mu?
  bool get canDownload => true;

  /// Share için uygun mu?
  bool get canShare => isImage || isDocument;

  /// Dosya boyutu placeholder (web'den size bilgisi gelmiyor)
  String get formattedFileSize => 'Boyut bilgisi mevcut değil';
}
