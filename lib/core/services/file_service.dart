// lib/core/services/file_service.dart - WEB API ENTEGRASYONU
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../data/services/api/api_client.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  static FileService get instance => _instance;
  FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// 📸 Kameradan fotoğraf çek
  Future<FileData?> capturePhoto() async {
    try {
      debugPrint('[FILE] Capturing photo from camera...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[FILE] Camera capture cancelled');
        return null;
      }

      return await _processImage(image);
    } catch (e) {
      debugPrint('[FILE] Camera capture error: $e');
      throw FileException('Fotoğraf çekilemedi: ${e.toString()}');
    }
  }

  /// 🖼️ Galeriden fotoğraf seç
  Future<FileData?> pickImageFromGallery() async {
    try {
      debugPrint('[FILE] Picking image from gallery...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[FILE] Gallery selection cancelled');
        return null;
      }

      return await _processImage(image);
    } catch (e) {
      debugPrint('[FILE] Gallery pick error: $e');
      throw FileException('Fotoğraf seçilemedi: ${e.toString()}');
    }
  }

  /// 📄 Dosya seç (PDF, DOC, etc.)
  Future<FileData?> pickFile() async {
    try {
      debugPrint('[FILE] Picking file...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE] File selection cancelled');
        return null;
      }

      final file = result.files.first;

      if (file.path == null) {
        throw FileException('Dosya yolu alınamadı');
      }

      final fileBytes = await File(file.path!).readAsBytes();

      return FileData(
        name: file.name,
        path: file.path!,
        bytes: fileBytes,
        size: file.size,
        mimeType: _getMimeType(file.extension ?? ''),
        isImage: false,
      );
    } catch (e) {
      debugPrint('[FILE] File pick error: $e');
      throw FileException('Dosya seçilemedi: ${e.toString()}');
    }
  }

  /// 🔄 Fotoğrafı işle ve sıkıştır
  Future<FileData> _processImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final compressedBytes = await _compressImage(bytes);

    return FileData(
      name: _generateFileName(image.name),
      path: image.path,
      bytes: compressedBytes,
      size: compressedBytes.length,
      mimeType: 'image/jpeg',
      isImage: true,
    );
  }

  /// 📦 Fotoğrafı sıkıştır
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Orijinal boyut kontrolü
      if (bytes.length <= 1024 * 1024) {
        // 1MB'dan küçükse sıkıştırma
        return bytes;
      }

      debugPrint('[FILE] Compressing image...');

      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Boyut kontrolü - max 1920x1080
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1080 : null,
        );
      }

      // JPEG olarak encode et
      final compressed = img.encodeJpg(resized, quality: 85);

      debugPrint('[FILE] Image compressed: ${bytes.length} -> ${compressed.length} bytes');

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('[FILE] Image compression error: $e');
      return bytes; // Hata durumunda orijinal döndür
    }
  }

  /// 📤 Dosyayı sunucuya yükle - WEB API'ye uygun format
  Future<AttachmentUploadResponse> uploadActivityFile({
    required int activityId,
    required FileData file,
    int? userId,
    int? formId = 8, // Activity form ID
    int? tableId = 102, // Activity table ID
  }) async {
    try {
      debugPrint('[FILE] Uploading file: ${file.name} for activity: $activityId');

      final base64File = base64Encode(file.bytes);
      final kendoUploadUid = "upload_${DateTime.now().millisecondsSinceEpoch}";

      // 🎯 WEB'deki request formatıyla birebir aynı
      final response = await ApiClient.post(
        '/api/Attachment/UploadFile',
        body: {
          "tableId": tableId,
          "recordId": activityId,
          "userId": userId ?? 5580, // Current user ID
          "formId": formId,
          "formName": "Aktivite",
          "kendoUploadUid": kendoUploadUid,
          "FileTypeInfo": "[]",
          "files": base64File,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[FILE] File uploaded successfully');
        debugPrint('[FILE] Upload response: $data');

        return AttachmentUploadResponse.fromJson(data);
      } else {
        debugPrint('[FILE] Upload failed: ${response.statusCode} - ${response.body}');
        throw FileException('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FILE] Upload error: $e');
      throw FileException('Dosya yüklenemedi: ${e.toString()}');
    }
  }

  /// 📥 Aktivitenin dosyalarını getir
  Future<AttachmentFileListResponse> getActivityFiles({
    required int activityId,
    int? tableId = 102,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('[FILE] Getting files for activity: $activityId');

      // 🎯 WEB'deki request formatıyla birebir aynı
      final response = await ApiClient.post(
        '/api/Attachment/GetFiles/',
        body: {
          "model": {
            "tableId": tableId,
            "recordId": activityId,
          },
          "take": pageSize,
          "skip": (page - 1) * pageSize,
          "page": page,
          "pageSize": pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[FILE] Files response: $data');

        return AttachmentFileListResponse.fromJson(data);
      } else {
        throw FileException('Failed to get files: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FILE] Get files error: $e');
      throw FileException('Dosyalar getirilemedi: ${e.toString()}');
    }
  }

  /// 🗑️ Dosyayı sil
  Future<AttachmentDeleteResponse> deleteActivityFile({
    required AttachmentFile file,
    required int activityId,
    int? tableId = 102,
  }) async {
    try {
      debugPrint('[FILE] Deleting file: ${file.fileName}');

      // 🎯 WEB'deki request formatıyla birebir aynı
      final response = await ApiClient.post(
        '/api/Attachment/DeleteFile/',
        body: {
          "model": {
            "tableId": tableId,
            "recordId": activityId,
          },
          "Id": file.id,
          "LocalName": file.localName,
          "FileName": file.fileName,
          "FileType": file.fileType,
          "CreatedUserName": file.createdUserName,
          "FormName": file.formName,
          "FileType_DDL": {
            "text": "",
            "value": file.fileType,
          },
          "CreatedDate": file.createdDate,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[FILE] Delete response: $data');

        return AttachmentDeleteResponse.fromJson(data);
      } else {
        throw FileException('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FILE] Delete error: $e');
      throw FileException('Dosya silinemedi: ${e.toString()}');
    }
  }

  /// 👁️ Dosya görüntüleme URL'i al
  Future<String?> getFileViewUrl(AttachmentFile file) async {
    try {
      debugPrint('[FILE] Getting view URL for: ${file.fileName}');

      // 🎯 WEB'deki request formatıyla aynı
      final response = await ApiClient.post(
        '/api/Attachment/FileToByteArrayOfImage',
        body: {"localName": file.localName, "filePath": "Media/Attachments"},
      );

      if (response.statusCode == 200) {
        // Base64 image data döndürüyor
        final base64Data = response.body;
        debugPrint('[FILE] Image data received, length: ${base64Data.length}');
        return 'data:image/jpeg;base64,$base64Data';
      }
    } catch (e) {
      debugPrint('[FILE] Get file view URL error: $e');
    }
    return null;
  }

  /// 💾 Geçici dosya kaydet
  Future<String> saveToTempDirectory(FileData file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');

      await tempFile.writeAsBytes(file.bytes);

      return tempFile.path;
    } catch (e) {
      throw FileException('Geçici dosya kaydedilemedi: ${e.toString()}');
    }
  }

  /// 📏 Dosya boyutunu formatla
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 🔍 MIME type belirle
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// 🔤 Benzersiz dosya adı oluştur
  String _generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return 'activity_file_$timestamp.$extension';
  }
}

/// 📄 Dosya verisi modeli
class FileData {
  final String name;
  final String path;
  final Uint8List bytes;
  final int size;
  final String mimeType;
  final bool isImage;

  FileData({
    required this.name,
    required this.path,
    required this.bytes,
    required this.size,
    required this.mimeType,
    required this.isImage,
  });

  String get formattedSize => FileService.instance.formatFileSize(size);

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size,
        'mimeType': mimeType,
        'isImage': isImage,
      };
}

/// ❌ Dosya exception'ı
class FileException implements Exception {
  final String message;
  FileException(this.message);

  @override
  String toString() => 'FileException: $message';
}
