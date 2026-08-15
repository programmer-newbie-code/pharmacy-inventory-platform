import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_inventory_platform/data/drive_upload_client.dart';

void main() {
  test('sends multipart metadata, authorization, and backup bytes', () async {
    final client = _CapturingClient(201, '{"id":"drive-file-id"}');
    final uploadClient = HttpDriveUploadClient(client: client);

    final id = await uploadClient.upload(
      accessToken: 'access-token',
      fileName: 'backup.json',
      bytes: utf8.encode('{"schemaVersion":2}'),
    );

    expect(id, 'drive-file-id');
    expect(client.request?.headers['Authorization'], 'Bearer access-token');
    final request = client.request! as http.MultipartRequest;
    expect(request.files.map((file) => file.field), containsAll(['metadata', 'file']));
  });

  test('creates or locates dedicated folder and attaches parent id', () async {
    final client = _MockDriveHttpClient();
    final uploadClient = HttpDriveUploadClient(client: client);

    final id = await uploadClient.upload(
      accessToken: 'access-token',
      fileName: 'backup.json',
      bytes: utf8.encode('{"schemaVersion":2}'),
      folderName: 'PharmaLoka_Backups',
    );

    expect(id, 'new-file-id');
    expect(client.uploadedMetadata?['parents'], contains('folder-123'));
  });

  test('maps unsuccessful Drive responses to a safe exception', () async {
    final uploadClient = HttpDriveUploadClient(
      client: _CapturingClient(403, 'permission denied'),
    );

    await expectLater(
      uploadClient.upload(
        accessToken: 'expired-token',
        fileName: 'backup.json',
        bytes: const [1],
      ),
      throwsA(isA<DriveUploadException>()),
    );
  });
}

class _MockDriveHttpClient extends http.BaseClient {
  Map<String, dynamic>? uploadedMetadata;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' && request.url.path.contains('/files')) {
      // Search folder returns existing folder
      final body = jsonEncode({
        'files': [
          {'id': 'folder-123', 'name': 'PharmaLoka_Backups'}
        ]
      });
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request is http.MultipartRequest) {
      final metadataFile = request.files.firstWhere((f) => f.field == 'metadata');
      // Read bytes from metadata file stream
      final bytes = await metadataFile.finalize().toBytes();
      uploadedMetadata = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final body = jsonEncode({'id': 'new-file-id'});
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _CapturingClient extends http.BaseClient {
  _CapturingClient(this.statusCode, this.body);

  final int statusCode;
  final String body;
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}
