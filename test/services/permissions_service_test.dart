import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:ofertapp_mobile/services/permissions_service.dart';

/// Fake del PermissionHandlerPlatform federado (mismo patrón que usan los
/// propios tests del paquete permission_handler): responde en memoria a
/// checkPermissionStatus() sin pasar por ningún canal de plataforma nativo,
/// así que no requiere dispositivo/emulador.
class _FakePermissionHandlerPlatform extends PermissionHandlerPlatform {
  _FakePermissionHandlerPlatform(this._statusPorPermiso);

  final Map<Permission, PermissionStatus> _statusPorPermiso;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return _statusPorPermiso[permission] ?? PermissionStatus.denied;
  }
}

// Prueba la función pura mapearEstadoPermiso directamente, sin pasar por
// PermissionsService ni por el plugin nativo (que requiere dispositivo).
void main() {
  group('mapearEstadoPermiso', () {
    test('granted -> concedido', () {
      expect(mapearEstadoPermiso(PermissionStatus.granted), EstadoPermiso.concedido);
    });

    test('limited -> concedido', () {
      expect(mapearEstadoPermiso(PermissionStatus.limited), EstadoPermiso.concedido);
    });

    test('permanentlyDenied -> denegadoPermanente', () {
      expect(mapearEstadoPermiso(PermissionStatus.permanentlyDenied),
          EstadoPermiso.denegadoPermanente);
    });

    test('restricted -> denegadoPermanente', () {
      expect(mapearEstadoPermiso(PermissionStatus.restricted),
          EstadoPermiso.denegadoPermanente);
    });

    test('denied -> denegado', () {
      // PermissionStatus.denied cubre tanto "nunca solicitado" como
      // "denegado" en permission_handler -- ver el comentario en
      // permissions_service.dart. Este es el caso real que ocurre en la
      // app para ubicación/cámara.
      expect(mapearEstadoPermiso(PermissionStatus.denied), EstadoPermiso.denegado);
    });

    test('provisional -> noSolicitado (único status que no cae en ningún otro caso)', () {
      expect(mapearEstadoPermiso(PermissionStatus.provisional),
          EstadoPermiso.noSolicitado);
    });
  });

  group('PermissionsService.estadoActualUbicacion', () {
    final plataformaOriginal = PermissionHandlerPlatform.instance;

    tearDown(() {
      PermissionHandlerPlatform.instance = plataformaOriginal;
    });

    test('consulta el status real de locationWhenInUse y lo mapea a concedido', () async {
      // Ejercita la rama que hoy no tenía ninguna prueba: la que de verdad
      // llama a Permission.locationWhenInUse.status (vía
      // PermissionHandlerPlatform.instance.checkPermissionStatus) y pasa el
      // resultado por mapearEstadoPermiso, en vez de probar solo la función
      // pura de mapeo por separado.
      PermissionHandlerPlatform.instance = _FakePermissionHandlerPlatform({
        Permission.locationWhenInUse: PermissionStatus.granted,
      });

      final estado = await PermissionsService.estadoActualUbicacion();

      expect(estado, EstadoPermiso.concedido);
    });
  });
}
