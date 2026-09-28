import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ofertapp_mobile/services/permissions_service.dart';

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
}
