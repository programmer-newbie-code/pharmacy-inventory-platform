import 'dart:convert';

import 'package:http/http.dart' as http;

class DriveUploadException implements Exception {
  DriveUploadException(this.message);

  final String message;

  @override
  String toString() => 'DriveUploadException: $message';
}

abstract interface class DriveUploadClient {
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  });
}

class HttpDriveUploadClient implements DriveUploadClient {
  HttpDriveUploadClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
    )
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromString(
        'metadata',
        jsonEncode({'name': fileName, 'mimeType': 'application/json'}),
        contentType: http.MediaType('application', 'json'),
      ))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        contentType: http.MediaType('application', 'json'),
      ));
    final response = await http.Response.fromStream(await _client.send(request));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriveUploadException('HTTP ${response.statusCode}: ${response.body}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['id'] is! String) {
      throw DriveUploadException('Google Drive did not return a file ID.');
    }
    return body['id'] as String;
  }
}
