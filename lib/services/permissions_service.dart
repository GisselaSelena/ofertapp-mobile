import 'package:permission_handler/permission_handler.dart';

enum EstadoPermiso { noSolicitado, concedido, denegado, denegadoPermanente }

class PermissionsService {
  static Future<EstadoPermiso> solicitarUbicacion() async {
    final status = await Permission.locationWhenInUse.request();
    return mapearEstadoPermiso(status);
  }

  static Future<EstadoPermiso> solicitarCamara() async {
    final status = await Permission.camera.request();
    return mapearEstadoPermiso(status);
  }

  static Future<EstadoPermiso> estadoActualUbicacion() async {
    return mapearEstadoPermiso(await Permission.locationWhenInUse.status);
  }

  static Future<EstadoPermiso> estadoActualCamara() async {
    return mapearEstadoPermiso(await Permission.camera.status);
  }

  static Future<void> abrirAjustesDelSistema() async {
    await openAppSettings();
  }
}

/// Función pura, separada de PermissionsService para poder probarla sin
/// tocar el plugin nativo permission_handler (que no puede correr sin
/// dispositivo/emulador). PermissionStatus.denied cubre tanto "nunca
/// solicitado" como "denegado" en permission_handler -- ver el orden de
/// los ifs: isDenied se chequea DESPUÉS de permanentemente denegado/
/// restringido, así que solo lo que sobra cae en noSolicitado (en la
/// práctica, para ubicación/cámara, ese caso no ocurre nunca -- ver
/// EstadoPermiso.noSolicitado).
EstadoPermiso mapearEstadoPermiso(PermissionStatus status) {
  if (status.isGranted || status.isLimited) return EstadoPermiso.concedido;
  if (status.isPermanentlyDenied || status.isRestricted) {
    return EstadoPermiso.denegadoPermanente;
  }
  if (status.isDenied) return EstadoPermiso.denegado;
  return EstadoPermiso.noSolicitado;
}