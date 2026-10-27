import 'dart:convert';
import 'dart:io';

Future<void> writeJsonError(
  HttpResponse response,
  int statusCode,
  String code,
  String message, {
  Map<String, dynamic> details = const {},
  String? requestId,
}) {
  return writeJsonResponse(response, statusCode, {
    'error': {
      'code': code,
      'message': message,
      if (details.isNotEmpty) 'details': details,
    },
    if (requestId != null) 'requestId': requestId,
  });
}

Future<void> writeJsonResponse(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await response.close();
}
