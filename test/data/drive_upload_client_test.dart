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
