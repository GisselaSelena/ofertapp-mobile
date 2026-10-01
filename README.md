# OfertApp Mobile

Aplicación móvil Flutter para comparar precios de productos entre establecimientos, consultar favoritos y reportar precios con evidencia opcional.

Repositorio del backend: <https://github.com/GisselaSelena/ofertapp-backend>

## Pantallas y navegación

La navegación se implementa con `go_router` y el estado compartido con Riverpod. Las rutas actuales son:

| Ruta | Pantalla | Función |
|---|---|---|
| `/login` | Inicio de sesión | Autenticación; si la sesión está activa redirige al catálogo. |
| `/register` | Crear cuenta | Registro de una cuenta de usuario. |
| `/productos` | Catálogo | Lista de productos, búsqueda y acceso a favoritos y perfil. |
| `/productos/nuevo` | Nuevo producto | Formulario para crear productos; disponible para administradores. |
| `/productos/editar` | Editar producto | Reutiliza el formulario de producto precargado; acceso desde las opciones de administración. |
| `/productos/:id/precios` | Comparar precios | Historial de precios vigentes y anteriores, establecimientos y resumen inteligente cuando está disponible. |
| `/productos/:id/precios/reportar` | Reportar precio | Selección de establecimiento, precio, ubicación opcional y foto opcional. |
| `/favoritos` | Mis favoritos | Consulta y eliminación de productos favoritos. |
| `/perfil` | Mi perfil | Datos de la cuenta, rol y cierre de sesión. En modo debug incluye un control para comprobar el reporte de errores a Sentry. |

Las rutas privadas requieren sesión. La app ofrece dos roles, `usuario` y `administrador`, informados por el backend. En el catálogo, solo el administrador ve el botón **Nuevo** y el menú de cada producto con **Editar** y **Eliminar**. Editar precarga nombre y categoría en el formulario. Eliminar primero solicita confirmación; si el servidor responde que el producto tiene precios, favoritos o promociones asociados, la app muestra sus conteos y ofrece **Cancelar** o **Eliminar todo**. Esta última opción vuelve a llamar al backend con `forzar=true`; si se confirma, el catálogo se refresca.

## Búsqueda

La búsqueda del catálogo filtra por nombre y categoría, sin distinguir mayúsculas. Espera 300 ms desde la última tecla antes de aplicar el filtro; las teclas nuevas cancelan el temporizador anterior. Borrar el campo muestra de nuevo todos los productos.

## Ubicación, cámara y permisos

Al reportar un precio se puede adjuntar la ubicación actual y una foto tomada con la cámara. Ambas son opcionales: se puede enviar el reporte sin una o ambas evidencias. La ubicación usa `geolocator` con precisión media y un límite de espera de 10 segundos. La foto se toma con `image_picker` y se reduce a calidad 70.

`PermissionsService` representa cuatro estados para cada permiso:

- **No solicitado** (`noSolicitado`): aún no hay una decisión disponible para la app.
- **Concedido** (`concedido`): puede usarse la ubicación o cámara.
- **Denegado** (`denegado`): se puede continuar sin esa evidencia.
- **Denegado permanentemente** (`denegadoPermanente`): la app explica cómo abrir Ajustes del sistema para habilitarlo.

Nota: `permission_handler` no diferencia en su estado `denied` entre “nunca solicitado” y “denegado”. Por eso, al usar ubicación o cámara la app solicita el permiso directamente; el estado `noSolicitado` está en el modelo, pero no siempre puede identificarse a partir de la respuesta nativa. iOS declara los propósitos de ubicación y cámara en `ios/Runner/Info.plist`.

## Configuración del backend

La URL base se lee desde `API_BASE_URL` en `lib/config.dart`. El valor por defecto corresponde a una IP de desarrollo y debe sustituirse si cambia la dirección del backend o la red local. Actualiza la IP en **ambos** lugares:

1. `lib/config.dart` (o proporciona `API_BASE_URL` al ejecutar Flutter).
2. La clave de dominio bajo `NSAppTransportSecurity > NSExceptionDomains` en `ios/Runner/Info.plist`, que habilita HTTP local para esa dirección.

Para sobrescribir la URL sin editar el código:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP_DEL_BACKEND>:8000
```

El dispositivo y el backend deben poder comunicarse en la red. El servidor local debe escuchar conexiones externas, por ejemplo con `uvicorn app.main:app --host 0.0.0.0`.

La excepción HTTP de iOS sirve para desarrollo local. En una distribución, el backend debe usar HTTPS y la excepción de tráfico no cifrado debe retirarse o ajustarse.

## Sentry y privacidad

La app inicializa Sentry desde `lib/utils/sentry_setup.dart`; el DSN se configura en `lib/config.dart` y puede sobrescribirse al compilar o ejecutar con:

```bash
flutter run --dart-define=SENTRY_DSN=<DSN_DE_SENTRY>
```

El DSN de cliente identifica el proyecto receptor de eventos; no es una contraseña ni permite consultar los datos de Sentry. No se incluyen aquí credenciales ni valores de DSN. La app configura `beforeSend` mediante `lib/utils/sentry_scrubber.dart`: elimina el correo del usuario, redacta valores de claves sensibles (como contraseñas, tokens y `Authorization`) y busca/redacta JWT en headers, tags, datos de breadcrumbs y mensajes. En el scope de Sentry se identifica la sesión solo con el ID interno del usuario, no con su correo. El muestreo de trazas está configurado al 20 %.

## Preparación y ejecución

Requisitos: Flutter y Dart compatibles con las versiones declaradas en `pubspec.yaml`, además de Xcode/CocoaPods para iOS o Android Studio/Android SDK para Android.

```bash
flutter pub get
flutter devices
flutter run -d <DEVICE_ID>
```

## Verificaciones

Análisis estático:

```bash
flutter analyze
```

Pruebas unitarias y de widgets:

```bash
flutter test
```

Prueba de integración del recorrido login → catálogo → detalle de precios:

```bash
flutter test integration_test/app_test.dart -d <DEVICE_ID>
```

La prueba de integración ejecuta la app, el router, las pantallas y los providers reales. Usa un cliente HTTP falso en memoria para las rutas de login, catálogo, precios y resumen de IA; no necesita un backend ni conexión a Internet, pero sí un simulador o dispositivo Flutter seleccionado. Las pruebas unitarias y de widgets también usan dobles para no depender del backend.
