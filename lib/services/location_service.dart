import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? lat;
  final double? lng;
  final String? error;

  LocationResult({this.lat, this.lng, this.error});

  bool get exito => lat != null && lng != null;
}

class LocationService {
  static Future<LocationResult> obtenerPosicionActual() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return LocationResult(
          error: 'El GPS del dispositivo está desactivado. Actívalo en Ajustes.');
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(lat: posicion.latitude, lng: posicion.longitude);
    } catch (e) {
      return LocationResult(error: 'No se pudo obtener la ubicación: $e');
    }
  }
}