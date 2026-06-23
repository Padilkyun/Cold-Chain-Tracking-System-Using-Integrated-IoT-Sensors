import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String _username = 'User Capsi';
  String _email = 'user@capsibox.com';
  String _phone = '08123456789';
  String _address = 'Bandung, Indonesia';
  String? _imagePath;

  String get username => _username;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String? get imagePath => _imagePath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'User Capsi';
    _email = prefs.getString('email') ?? 'user@capsibox.com';
    _phone = prefs.getString('phone') ?? '08123456789';
    _address = prefs.getString('address') ?? 'Bandung, Indonesia';
    _imagePath = prefs.getString('imagePath');
    notifyListeners();
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    required String phone,
    required String address,
    String? imagePath,
  }) async {
    _username = username;
    _email = email;
    _phone = phone;
    _address = address;
    if (imagePath != null) _imagePath = imagePath;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setString('email', _email);
    await prefs.setString('phone', _phone);
    await prefs.setString('address', _address);
    if (_imagePath != null) await prefs.setString('imagePath', _imagePath!);
    
    notifyListeners();
  }
}
