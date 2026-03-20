import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class ApiService {
  Future<dynamic> get(String endpoint, {String? token}) async {
    final url = Uri.parse("${Api.baseUrl}/$endpoint");
    debugPrint("ApiService: GET $url");
    
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String endpoint, Map body, {String? token}) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String endpoint, Map body, {String? token}) async {
    final response = await http.patch(
      Uri.parse("${Api.baseUrl}/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }


  Future<dynamic> postMultipart(String endpoint, Map<String, String> body,
      {String? token, String? filePath, Uint8List? bytes, String? fieldName}) async {
    final request =
        http.MultipartRequest('POST', Uri.parse("${Api.baseUrl}/$endpoint"));

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(body);

    if (fieldName != null) {
      if (kIsWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: "upload.png"));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  Future<dynamic> patchMultipart(String endpoint, Map<String, String> body,
      {String? token, String? filePath, Uint8List? bytes, String? fieldName}) async {
    final request =
        http.MultipartRequest('PATCH', Uri.parse("${Api.baseUrl}/$endpoint"));

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(body);

    if (fieldName != null) {
      if (kIsWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: "profile.png"));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }
}



