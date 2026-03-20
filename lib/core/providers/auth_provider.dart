import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  final ApiService _api = ApiService();

  AuthProvider() {
    _loadAuthData();
  }

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _user = json.decode(userData);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('auth/login', {
        'email': email,
        'password': password,
      });

      if (response != null && response['access_token'] != null) {
        _token = response['access_token'];
        _user = response['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_user));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _api.post('auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response != null && response['message'] != null) {
        // Just return true to indicate success, don't store token yet
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Register error: $e");
      return false;
    }
  }


  Future<bool> updateProfile(String name, String email, {String? imagePath, Uint8List? imageBytes}) async {
    try {
      final response = await _api.patchMultipart(
        'user/profile',
        {'name': name, 'email': email},
        token: _token,
        filePath: imagePath,
        bytes: imageBytes,
        fieldName: 'image',
      );

      if (response != null && response['updatedUser'] != null) {
        _user = response['updatedUser'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(_user));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("UpdateProfile error: $e");
      return false;
    }
  }

  Future<void> logout() async {

    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
