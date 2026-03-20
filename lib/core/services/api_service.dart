import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class ApiService {
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse("${Api.baseUrl}/$endpoint");
    debugPrint("ApiService: GET $url");
    final response = await http.get(url);
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String endpoint, Map body) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/$endpoint"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }
}
