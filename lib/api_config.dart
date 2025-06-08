import 'dart:async';
import 'package:http/http.dart' as http;

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;

  ApiConfig._internal();

  final String _railwayUrl = "https://serverpos-production.up.railway.app";
  String get baseUrl => _railwayUrl;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final reachable = await _isServerAvailable();
    if (!reachable) {
      print("[ApiConfig] Railway server tidak dapat dijangkau.");
      // Kamu bisa tambahkan alert atau retry logic jika perlu
    } else {
      print("[ApiConfig] Terhubung ke Railway server.");
    }
  }

  Future<bool> _isServerAvailable() async {
    try {
      final response = await http
          .get(Uri.parse("$_railwayUrl/user/ping"))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  bool get isReady => _initialized;
}
