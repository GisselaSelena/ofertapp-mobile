import 'package:permission_handler/permission_handler.dart';

enum EstadoPermiso { noSolicitado, concedido, denegado, denegadoPermanente }

class PermissionsService {
  static Future<EstadoPermiso> solicitarUbicacion() async {
    final status = await Permission.locationWhenInUse.request();
    return _mapear(status);
  }

  static Future<EstadoPermiso> solicitarCamara() async {
    final status = await Permission.camera.request();
    return _mapear(status);
  }

  static Future<EstadoPermiso> estadoActualUbicacion() async {
    return _mapear(await Permission.locationWhenInUse.status);
  }

  static Future<EstadoPermiso> estadoActualCamara() async {
    return _mapear(await Permission.camera.status);
  }

  static EstadoPermiso _mapear(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return EstadoPermiso.concedido;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return EstadoPermiso.denegadoPermanente;
    }
    if (status.isDenied) return EstadoPermiso.denegado;
    return EstadoPermiso.noSolicitado;
  }

  static Future<void> abrirAjustesDelSistema() async {
    await openAppSettings();
  }
}