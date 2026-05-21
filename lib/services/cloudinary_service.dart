import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  const CloudinaryService();

  static const _configuredCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const _defaultCloudName = 'dpqzzyfdk';

  static const _configuredUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const _defaultUploadPreset = 'profile_uploads';

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cloudName = _configuredCloudName.isNotEmpty
        ? _configuredCloudName
        : _defaultCloudName;
    final uploadPreset = _configuredUploadPreset.isNotEmpty
        ? _configuredUploadPreset
        : _defaultUploadPreset;

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw const CloudinaryConfigException(
        'Cloudinary is not configured.\n'
        'Add:\n'
        '--dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name\n'
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=profile_uploads',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw CloudinaryUploadException(
        'Cloudinary upload failed '
        '(${streamedResponse.statusCode}): $responseBody',
      );
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    final secureUrl = data['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary did not return an image URL.',
      );
    }

    return secureUrl;
  }
}

class CloudinaryConfigException implements Exception {
  const CloudinaryConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
