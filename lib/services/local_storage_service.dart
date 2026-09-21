import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyUltimaLat = 'ultima_lat';
  static const _keyUltimaLng = 'ultima_lng';
  static const _keyUltimaFotoPath = 'ultima_foto_path';

  static Future<void> guardarUltimaUbicacion(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUltimaLat, lat);
    await prefs.setDouble(_keyUltimaLng, lng);
  }

  static Future<(double, double)?> leerUltimaUbicacion() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyUltimaLat);
    final lng = prefs.getDouble(_keyUltimaLng);
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  static Future<void> guardarUltimaFotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaFotoPath, path);
  }

  static Future<String?> leerUltimaFotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUltimaFotoPath);
  }
}