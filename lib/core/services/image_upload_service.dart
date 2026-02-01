import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 이미지 업로드 서비스 Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService(Supabase.instance.client);
});

/// 이미지 업로드 서비스
class ImageUploadService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker = ImagePicker();

  static const String _bucketName = 'user-cocktail-images';
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB

  ImageUploadService(this._supabase);

  /// 갤러리에서 이미지 선택 (3:4 세로 비율 최적화)
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1440, // 3:4 비율 (세로 방향)
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  /// 카메라로 이미지 촬영 (3:4 세로 비율 최적화)
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1440, // 3:4 비율 (세로 방향)
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    return image != null ? File(image.path) : null;
  }

  /// 칵테일 이미지 업로드
  /// 반환: 업로드된 이미지의 public URL 또는 null (실패 시)
  Future<String?> uploadCocktailImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 파일 크기 확인
      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSize) {
        throw Exception('이미지 크기는 5MB를 초과할 수 없습니다.');
      }

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExt)) {
        throw Exception('지원하지 않는 이미지 형식입니다.');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from(_bucketName).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      // 에러 로깅
      return null;
    }
  }

  /// 이미지 삭제
  Future<bool> deleteCocktailImage(String imageUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // URL에서 파일 경로 추출
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      // 'user-cocktail-images/userId/fileName' 형태에서 경로 추출
      final bucketIndex = segments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex + 2 >= segments.length) {
        return false;
      }

      final filePath = '${segments[bucketIndex + 1]}/${segments[bucketIndex + 2]}';

      // 본인 이미지만 삭제 가능
      if (!filePath.startsWith(userId)) {
        return false;
      }

      await _supabase.storage.from(_bucketName).remove([filePath]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
