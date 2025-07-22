// lib/data/models/attachment/attachment_file_model.dart - WEB API UYUMLU
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

  // 🎯 GetFiles API response'u için (Data array içindeki objeler)
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

  // 🎯 UploadFile API response'u için (Attachments array içindeki objeler)
  factory AttachmentFile.fromUploadResponse(Map<String, dynamic> json) {
    return AttachmentFile(
      id: json['Id'] ?? 0,
      fileName: json['FileName'] ?? '',
      localName: json['LocalName'] ?? '',
      fileType: json['FileType'] ?? 0,
      createdUserName: '', // Upload response'da CreatedUserName yok
      createdDate: json['CreatedDate'] ?? '',
      formName: json['FormName'] ?? '',
      tableId: json['TableId'],
      recordId: json['RecordId'],
      formId: json['FormId'],
    );
  }

  bool get isImage => fileType == 0;
  bool get isDocument => fileType == 1;

  String get fileTypeText {
    switch (fileType) {
      case 0:
        return 'Resim';
      case 1:
        return 'Doküman';
      default:
        return 'Bilinmeyen';
    }
  }

  /// 📱 Mobile için display formatı
  String get displayFileName {
    // Uzun dosya adlarını kısalt
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
      // Eğer parse edilemezse, orijinal string'i döndür
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

  /// 📋 Copy with method
  AttachmentFile copyWith({
    int? id,
    String? fileName,
    String? localName,
    int? fileType,
    String? createdUserName,
    String? createdDate,
    String? formName,
    int? tableId,
    int? recordId,
    int? formId,
  }) {
    return AttachmentFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localName: localName ?? this.localName,
      fileType: fileType ?? this.fileType,
      createdUserName: createdUserName ?? this.createdUserName,
      createdDate: createdDate ?? this.createdDate,
      formName: formName ?? this.formName,
      tableId: tableId ?? this.tableId,
      recordId: recordId ?? this.recordId,
      formId: formId ?? this.formId,
    );
  }

  /// ⚖️ Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttachmentFile && other.id == id && other.fileName == fileName && other.localName == localName;
  }

  @override
  int get hashCode => Object.hash(id, fileName, localName);
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
    final dataList = json['Data'] as List<dynamic>? ?? [];
    final files = dataList.map((item) => AttachmentFile.fromJson(item as Map<String, dynamic>)).toList();

    return AttachmentFileListResponse(
      data: files,
      total: json['Total'] as int? ?? 0,
      aggregates: json['Aggregates'] as Map<String, dynamic>?,
      errors: (json['Errors'] as List<dynamic>?)?.cast<String>(),
    );
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
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
    final attachmentsList = json['Attachments'] as List<dynamic>? ?? [];
    final files = attachmentsList.map((item) => AttachmentFile.fromUploadResponse(item as Map<String, dynamic>)).toList();

    return AttachmentUploadResponse(
      status: json['Status'] as bool? ?? false,
      attachments: files,
      errorMessage: json['ErrorMessage'] as String?,
    );
  }

  bool get isSuccess => status && errorMessage == null;
  bool get hasFiles => attachments.isNotEmpty;
  AttachmentFile? get firstFile => attachments.isNotEmpty ? attachments.first : null;
}

/// 🗑️ Delete response modeli
class AttachmentDeleteResponse {
  final String status;
  final String? message;

  AttachmentDeleteResponse({
    required this.status,
    this.message,
  });

  factory AttachmentDeleteResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentDeleteResponse(
      status: json['Status'] as String? ?? '',
      message: json['Message'] as String?,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

/// 📁 Dosya türü enum'u
enum AttachmentFileType {
  image(0, 'Resim', Icons.image, Colors.green),
  document(1, 'Doküman', Icons.description, Colors.blue);

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
  /// Dosya boyutu human-readable format
  String get formattedFileSize {
    // Web'den gelen response'da file size yok, bu durumda placeholder
    return 'Boyut bilgisi yok';
  }

  /// Preview için uygun mu?
  bool get canPreview => isImage;

  /// Download için uygun mu?
  bool get canDownload => true;

  /// Share için uygun mu?
  bool get canShare => isImage || isDocument;
}
