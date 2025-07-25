// lib/core/services/file_service.dart - Duplicate method hatası düzeltildi
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api/api_client.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  static FileService get instance => _instance;
  FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// 📸 Kameradan fotoğraf çek - Güvenli versiyon
  Future<FileData?> capturePhoto() async {
    try {
      debugPrint('[FILE] 📸 Capturing photo from camera...');

      // Kamera için güvenlik kontrolü ve retry mantığı
      XFile? image;

      try {
        image = await _imagePicker
            .pickImage(
          source: ImageSource.camera,
          maxWidth: 1024, // Daha düşük çözünürlük - memory için
          maxHeight: 1024,
          imageQuality: 100, // Daha düşük kalite - performance için
          preferredCameraDevice: CameraDevice.rear,
        )
            .timeout(
          Duration(seconds: 30), // 30 saniye timeout
          onTimeout: () {
            debugPrint('[FILE] ❌ Camera timeout');
            throw FileException('Kamera zaman aşımına uğradı');
          },
        );
      } catch (e) {
        debugPrint('[FILE] ❌ Camera picker error: $e');

        // Spesifik hata handling
        if (e.toString().contains('photo_access_denied')) {
          throw FileException('Kamera izni reddedildi. Ayarlardan izin verin.');
        } else if (e.toString().contains('camera_access_denied')) {
          throw FileException('Kamera erişimi reddedildi.');
        } else if (e.toString().contains('no_available_camera')) {
          throw FileException('Kullanılabilir kamera bulunamadı.');
        } else {
          throw FileException('Kamera hatası: ${e.toString()}');
        }
      }

      if (image == null) {
        debugPrint('[FILE] ❌ Camera capture cancelled by user');
        return null;
      }

      debugPrint('[FILE] ✅ Camera photo captured: ${image.name}');
      debugPrint('[FILE] 📍 Image path: ${image.path}');

      // Dosya mevcut mu kontrol et
      final file = File(image.path);
      if (!await file.exists()) {
        throw FileException('Çekilen fotoğraf dosyası bulunamadı');
      }

      return await _processImage(image);
    } catch (e) {
      debugPrint('[FILE] ❌ Camera capture error: $e');

      if (e is FileException) {
        rethrow;
      }

      throw FileException('Fotoğraf çekilemedi: ${e.toString()}');
    }
  }

  /// 🖼️ Galeriden fotoğraf seç
  Future<FileData?> pickImageFromGallery() async {
    try {
      debugPrint('[FILE] 🖼️ Picking image from gallery...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 100,
      );

      if (image == null) {
        debugPrint('[FILE] ❌ Gallery selection cancelled');
        return null;
      }

      debugPrint('[FILE] ✅ Gallery image selected: ${image.name}');
      return await _processImage(image);
    } catch (e) {
      debugPrint('[FILE] ❌ Gallery pick error: $e');
      throw FileException('Fotoğraf seçilemedi: ${e.toString()}');
    }
  }

  /// 📄 Dosya seç (PDF, DOC, etc.)
  Future<FileData?> pickFile() async {
    try {
      debugPrint('[FILE] 📄 Picking file...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE] ❌ File selection cancelled');
        return null;
      }

      final file = result.files.first;

      if (file.path == null) {
        throw FileException('Dosya yolu alınamadı');
      }

      final fileBytes = await File(file.path!).readAsBytes();

      debugPrint('[FILE] ✅ File selected: ${file.name} (${_formatBytes(file.size)})');

      return FileData(
        name: file.name,
        path: file.path!,
        bytes: fileBytes,
        size: file.size,
        mimeType: _getMimeType(file.extension ?? ''),
        isImage: false,
      );
    } catch (e) {
      debugPrint('[FILE] ❌ File pick error: $e');
      throw FileException('Dosya seçilemedi: ${e.toString()}');
    }
  }

  /// 🔄 Fotoğrafı işle ve sıkıştır
  Future<FileData> _processImage(XFile image) async {
    try {
      debugPrint('[FILE] 🔄 Processing image: ${image.name}');

      final bytes = await image.readAsBytes();
      debugPrint('[FILE] 📊 Original image size: ${_formatBytes(bytes.length)}');

      final compressedBytes = await _compressImage(bytes);
      debugPrint('[FILE] 📦 Compressed image size: ${_formatBytes(compressedBytes.length)}');

      return FileData(
        name: _generateFileName(image.name),
        path: image.path,
        bytes: compressedBytes,
        size: compressedBytes.length,
        mimeType: 'image/jpeg',
        isImage: true,
      );
    } catch (e) {
      debugPrint('[FILE] ❌ Image processing error: $e');
      throw FileException('Resim işlenemedi: ${e.toString()}');
    }
  }

  /// 📦 Fotoğrafı sıkıştır
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Orijinal boyut kontrolü - 1MB'dan küçükse sıkıştırma
      if (bytes.length <= 1024 * 1024) {
        debugPrint('[FILE] ⚡ Image is small enough, skipping compression');
        return bytes;
      }

      debugPrint('[FILE] 📦 Compressing image...');

      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('[FILE] ❌ Cannot decode image for compression');
        return bytes;
      }

      // Boyut kontrolü - max 1920x1080
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1080 : null,
        );
        debugPrint('[FILE] 🔧 Image resized from ${image.width}x${image.height} to ${resized.width}x${resized.height}');
      }

      // JPEG olarak encode et
      final compressed = img.encodeJpg(resized, quality: 85);
      debugPrint('[FILE] ✅ Image compressed: ${bytes.length} -> ${compressed.length} bytes');

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('[FILE] ❌ Image compression error: $e');
      return bytes; // Hata durumunda orijinal döndür
    }
  }

  /// 📤 Dosyayı sunucuya yükle - Geliştirilmiş versiyon
  Future<AttachmentUploadResponse> uploadActivityFile({
    required int activityId,
    required FileData file,
    int? userId,
    int? formId = 8,
    int? tableId = 102,
  }) async {
    try {
      debugPrint('[FILE] 🚀 UPLOADING FILE: ${file.name} for activity: $activityId');
      debugPrint('[FILE] 📁 File size: ${_formatBytes(file.size)}');
      debugPrint('[FILE] 📁 File type: ${file.mimeType}');

      // 🎯 Auth bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final subdomain = prefs.getString('subdomain') ?? 'demo';
      final token = prefs.getString('token') ?? '';
      final currentUserId = prefs.getInt('userId') ?? 5580;

      if (token.isEmpty) {
        throw FileException('Kimlik doğrulama token\'ı bulunamadı');
      }

      // 🎯 Kendo Upload UID oluştur
      final kendoUploadUid = _generateKendoUploadUid();
      final baseUrl = 'https://$subdomain.veribiscrm.com';

      // Query parameters
      final queryParams = {
        'tableId': tableId.toString(),
        'recordId': activityId.toString(),
        'userId': (userId ?? currentUserId).toString(),
        'formId': formId.toString(),
        'formName': 'Aktivite',
        'kendoUploadUid': kendoUploadUid,
        'FileTypeInfo': '[]',
      };

      // URL'i oluştur
      final uri = Uri.parse('$baseUrl/api/Attachment/UploadFile').replace(queryParameters: queryParams);

      debugPrint('[FILE] 📤 Request URL: $uri');
      debugPrint('[FILE] 🔑 Upload UID: $kendoUploadUid');

      // HTTP Client ile multipart request
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': 'Flutter Mobile App',
      });

      // 🎯 Dosyayı ekle
      final multipartFile = http.MultipartFile.fromBytes(
        'files', // Field name - web'dekiyle aynı
        file.bytes,
        filename: file.name,
      );

      request.files.add(multipartFile);

      debugPrint('[FILE] 📤 Sending request with ${file.bytes.length} bytes');
      debugPrint('[FILE] 📤 Content Type: ${multipartFile.contentType}');

      // Timeout ile request gönder
      final streamedResponse = await request.send().timeout(
        Duration(minutes: 3),
        onTimeout: () {
          throw TimeoutException('Upload timeout', Duration(minutes: 3));
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[FILE] 📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          debugPrint('[FILE] 📊 Response data keys: ${data.keys.toList()}');

          if (data['Status'] == true) {
            debugPrint('[FILE] ✅ Upload successful!');

            final uploadResponse = AttachmentUploadResponse.fromJson(data);
            debugPrint('[FILE] 📊 Uploaded ${uploadResponse.attachments.length} files');

            return uploadResponse;
          } else {
            final errorMsg = data['Message'] ?? data['ErrorMessage'] ?? 'Upload failed';
            debugPrint('[FILE] ❌ Upload failed - Server returned: $errorMsg');
            throw FileException('Upload failed: $errorMsg');
          }
        } catch (e) {
          debugPrint('[FILE] ❌ JSON Parse error: $e');
          debugPrint('[FILE] ❌ Raw response: ${response.body.length > 500 ? "${response.body.substring(0, 500)}..." : response.body}');
          throw FileException('Response parse error: ${e.toString()}');
        }
      } else {
        debugPrint('[FILE] ❌ HTTP Error: ${response.statusCode}');
        debugPrint('[FILE] ❌ Response body: ${response.body}');

        String errorMessage = _getHttpErrorMessage(response.statusCode);
        throw FileException(errorMessage);
      }
    } on TimeoutException catch (e) {
      debugPrint('[FILE] ❌ Timeout error: $e');
      throw FileException('Yükleme zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.');
    } on SocketException catch (e) {
      debugPrint('[FILE] ❌ Network error: $e');
      throw FileException('İnternet bağlantısı hatası. Bağlantınızı kontrol edin.');
    } catch (e) {
      debugPrint('[FILE] ❌ Upload error: $e');

      String userMessage;
      if (e is FileException) {
        userMessage = e.message;
      } else {
        userMessage = 'Dosya yüklenemedi: ${e.toString()}';
      }

      throw FileException(userMessage);
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
      debugPrint('[FILE] 📂 Getting files for activity: $activityId');

      final requestBody = {
        "model": {
          "tableId": tableId,
          "recordId": activityId,
        },
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize,
      };

      final response = await ApiClient.post(
        '/api/Attachment/GetFiles/',
        body: requestBody,
      );

      debugPrint('[FILE] 📥 GetFiles response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[FILE] 📊 Files response: Found ${data['Total'] ?? 0} files');

        return AttachmentFileListResponse.fromJson(data);
      } else {
        throw FileException('Failed to get files: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FILE] ❌ Get files error: $e');
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
      debugPrint('[FILE] 🗑️ Deleting file: ${file.fileName}');

      final requestBody = {
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
      };

      final response = await ApiClient.post(
        '/api/Attachment/DeleteFile/',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AttachmentDeleteResponse.fromJson(data);
      } else {
        throw FileException('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FILE] ❌ Delete error: $e');
      throw FileException('Dosya silinemedi: ${e.toString()}');
    }
  }

  /// 👁️ Dosya görüntüleme URL'i al
  Future<String?> getFileViewUrl(AttachmentFile file) async {
    try {
      debugPrint('[FILE] 👁️ Getting view URL for: ${file.fileName}');

      final requestBody = {"localName": file.localName, "filePath": "Media/Attachments"};

      final response = await ApiClient.post(
        '/api/Attachment/FileToByteArrayOfImage',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final base64Data = response.body;
        String cleanBase64 = base64Data.replaceAll('"', '');
        return 'data:image/jpeg;base64,$cleanBase64';
      } else {
        debugPrint('[FILE] ❌ Failed to get view URL: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[FILE] ❌ Get file view URL error: $e');
      return null;
    }
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
    return _formatBytes(bytes);
  }

  // ====================
  // PRIVATE HELPER METHODS
  // ====================

  /// 📏 Bytes formatla
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 🔍 HTTP hata mesajları
  String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek. Dosya formatını kontrol edin.';
      case 401:
        return 'Yetkilendirme hatası. Tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz yok.';
      case 413:
        return 'Dosya çok büyük. Maksimum boyut: 10MB';
      case 415:
        return 'Desteklenmeyen dosya formatı.';
      case 422:
        return 'Dosya işlenemedi. Format hatası olabilir.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      case 502:
        return 'Sunucu geçici olarak erişilemiyor.';
      case 503:
        return 'Servis geçici olarak kullanılamıyor.';
      default:
        return 'Upload hatası (HTTP $statusCode)';
    }
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

  /// 🆔 Kendo Upload UID oluştur (web'dekiyle uyumlu format)
  String _generateKendoUploadUid() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random();

    // UUID benzeri format oluştur
    final part1 = (timestamp % 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final part2 = random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    final part3 = random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    final part4 = random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    final part5 = random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');

    return '$part1-$part2-$part3-$part4-$part5';
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

  @override
  String toString() {
    return 'FileData(name: $name, size: $formattedSize, mimeType: $mimeType, isImage: $isImage)';
  }
}

/// ❌ Dosya exception'ı
class FileException implements Exception {
  final String message;
  FileException(this.message);

  @override
  String toString() => 'FileException: $message';
}
