import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'notification_service.dart';

class EspService extends ChangeNotifier {
  static final EspService _instance = EspService._internal();
  factory EspService() => _instance;
  EspService._internal();

  final String _baseUrl = 'http://192.168.4.1';
  final String _dataEndpoint = '/data'; 
  
  Timer? _timer;
  bool _isPolling = false;
  final _dbHelper = DatabaseHelper();
  final _notifService = NotificationService();

  // Connection State
  bool isConnected = false;
  bool espNowConnected = true;
  
  // Track alert states to avoid spamming
  bool _tvocAlertSent = false;
  bool _disconnectAlertSent = false;

  // Sensor & Actuator Data
  double suhu = 0.0;
  double kelembaban = 0.0;
  int tvoc = 0;
  int eco2 = 0;
  int peltierPwm = 0;
  bool modeAuto = true;
  bool manualPeltier = false;
  bool manualKipas = true;
  double setpoint = 19.0;
  bool teaCutterActive = false;
  int teaCutterSpeed = 50;

  // Alerts
  final StreamController<String> _alertController = StreamController<String>.broadcast();
  Stream<String> get alerts => _alertController.stream;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchData();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _isPolling = false;
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_dataEndpoint')).timeout(
        const Duration(milliseconds: 3000),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        suhu = (data['suhu'] as num).toDouble();
        kelembaban = (data['kelembaban'] as num).toDouble();
        tvoc = (data['tvoc'] as num).toInt();
        eco2 = (data['eco2'] as num).toInt();
        peltierPwm = (data['peltier_pwm'] as num).toInt();
        
        modeAuto = _toBool(data['mode_auto']);
        manualPeltier = _toBool(data['manual_peltier']);
        manualKipas = _toBool(data['manual_kipas']);
        setpoint = (data['setpoint'] as num).toDouble();
        teaCutterActive = _toBool(data['tea_cutter_active']);
        teaCutterSpeed = (data['tea_cutter_speed'] as num).toInt();
        
        bool prevEspNow = espNowConnected;
        espNowConnected = _toBool(data['esp_now_connected'] ?? true);

        // Alerts
        if (tvoc >= 1000) {
          String msg = "⚠️ Bahaya! TVOC Tinggi: $tvoc ppb";
          _alertController.add(msg);
          if (!_tvocAlertSent) {
            String title = "Peringatan CapsiBox";
            String body = "Kadar gas berbahaya (TVOC) terdeteksi tinggi!";
            _notifService.showNotification(
              id: 1,
              title: title,
              body: body,
            );
            _dbHelper.insertNotification(title, body);
            _tvocAlertSent = true;
          }
        } else {
          _tvocAlertSent = false;
        }

        if (prevEspNow && !espNowConnected) {
          String msg = "❌ Sensor Terputus! (ESP-NOW Error)";
          String title = "Koneksi Terputus";
          String body = "Sensor pemancar (ESP1) tidak merespons.";
          _alertController.add(msg);
          _notifService.showNotification(
            id: 2,
            title: title,
            body: body,
          );
          _dbHelper.insertNotification(title, body);
        } else if (!prevEspNow && espNowConnected) {
          String msg = "✅ Sensor Terhubung Kembali";
          String title = "Koneksi Pulih";
          String body = "Sensor pemancar telah terhubung kembali.";
          _alertController.add(msg);
          _notifService.showNotification(
            id: 3,
            title: title,
            body: body,
          );
          _dbHelper.insertNotification(title, body);
        }

        // Save to SQLite
        await _dbHelper.insertData({
          'suhu': suhu,
          'kelembaban': kelembaban,
          'tvoc': tvoc,
          'eco2': eco2,
        });
        
        if (!isConnected) {
          isConnected = true;
        }
        notifyListeners();
      } else {
        _setDisconnected();
      }
    } catch (e) {
      _setDisconnected();
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  void _setDisconnected() {
    if (isConnected) {
      isConnected = false;
      notifyListeners();
    }
  }

  Future<bool> sendControl(Map<String, dynamic> params) async {
    try {
      final Map<String, String> stringParams = {};
      params.forEach((key, value) {
        if (value is bool) {
          stringParams[key] = value ? '1' : '0';
        } else {
          stringParams[key] = value.toString();
        }
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/control'),
        body: stringParams,
      ).timeout(const Duration(milliseconds: 2000));

      if (response.statusCode == 200) {
        // Record action in database
        params.forEach((key, value) {
          String actionTitle = "";
          switch (key) {
            case 'mode_auto':
              actionTitle = value == 1 ? "Mode diatur ke Otomatis" : "Mode diatur ke Manual";
              break;
            case 'manual_peltier':
              actionTitle = value == 1 ? "Peltier diaktifkan" : "Peltier dinonaktifkan";
              break;
            case 'manual_kipas':
              actionTitle = value == 1 ? "Kipas diaktifkan" : "Kipas dinonaktifkan";
              break;
            case 'setpoint':
              actionTitle = "Setpoint diubah ke $value°C";
              break;
            case 'tea_cutter_active':
              actionTitle = value == 1 ? "Pemotong Teh diaktifkan" : "Pemotong Teh dinonaktifkan";
              break;
            case 'tea_cutter_speed':
              actionTitle = "Kecepatan Pemotong diatur ke $value%";
              break;
          }
          if (actionTitle.isNotEmpty) {
            _dbHelper.insertAction(actionTitle);
          }
        });

        fetchData(); // Refresh data after control
        return true;
      }
    } catch (e) {
      if (kDebugMode) print("[ESP] Error sending command: $e");
    }
    return false;
  }
}
