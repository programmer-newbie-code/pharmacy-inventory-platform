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
    String? folderName,
  });
}

class HttpDriveUploadClient implements DriveUploadClient {
  HttpDriveUploadClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String?> _getOrCreateFolder({
    required String accessToken,
    required String folderName,
  }) async {
    final searchUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent("mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false")}&fields=${Uri.encodeComponent("files(id, name)")}',
    );
    final searchResponse = await _client.get(
      searchUri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (searchResponse.statusCode == 200) {
      final searchBody = jsonDecode(searchResponse.body);
      if (searchBody is Map<String, dynamic> &&
          searchBody['files'] is List &&
          (searchBody['files'] as List).isNotEmpty) {
        final first = (searchBody['files'] as List).first;
        if (first is Map<String, dynamic> && first['id'] is String) {
          return first['id'] as String;
        }
      }
    }

    final createResponse = await _client.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
      final createBody = jsonDecode(createResponse.body);
      if (createBody is Map<String, dynamic> && createBody['id'] is String) {
        return createBody['id'] as String;
      }
    }

    return null;
  }

  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
    String? folderName,
  }) async {
    String? folderId;
    if (folderName != null && folderName.trim().isNotEmpty) {
      try {
        folderId = await _getOrCreateFolder(
          accessToken: accessToken,
          folderName: folderName.trim(),
        );
      } catch (_) {}
    }

    final metadata = <String, dynamic>{
      'name': fileName,
      'mimeType': 'application/json',
      if (folderId != null) 'parents': [folderId],
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
    )
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromString(
        'metadata',
        jsonEncode(metadata),
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
