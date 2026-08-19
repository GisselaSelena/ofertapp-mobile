# OfertApp — Mobile (Flutter)

Aplicación móvil de OfertApp, un comparador de precios de productos entre
distintos establecimientos comerciales. Construida con Flutter, consume
la API REST del backend de OfertApp (FastAPI + SQLAlchemy).

Repositorio del backend: https://github.com/GisselaSelena/ofertapp-backend

## Framework y justificación

Se utilizó **Flutter** por ser un framework multiplataforma que permite
compilar para iOS y Android desde una única base de código en Dart, con
un motor de renderizado propio (Impeller/Skia) que ofrece rendimiento
cercano al nativo y un ciclo de desarrollo rápido gracias al hot reload.

## Entorno de desarrollo

Versiones utilizadas durante el desarrollo:

```
Flutter 3.47.0 • channel stable
Dart 3.13.0
Xcode 26.6
Android SDK 36.0.0
macOS 26.5.2 (darwin-arm64)
```

Verificación del entorno:

```bash
flutter doctor
```

Salida esperada: `No issues found!`

### Herramientas instaladas

- Flutter SDK (`brew install --cask flutter`)
- Xcode, con soporte para iOS 26.5 y CocoaPods (`brew install cocoapods`)
- Android Studio, con Android SDK, Command-line Tools y licencias
  aceptadas (`flutter doctor --android-licenses`)
- VS Code con la extensión de Flutter/Dart

## Destino de ejecución

Se utilizó un **iPhone físico** (iPhone 15, iOS 26.6) conectado por
cable, en lugar de un simulador. Esta decisión se tomó porque la
depuración sobre dispositivo real permite validar el comportamiento
efectivo de la conectividad de red hacia el backend (los simuladores de
iOS comparten la red del host de forma distinta a un dispositivo físico
en la misma LAN), además de reflejar con mayor fidelidad el rendimiento
real que tendrá la aplicación final.

Para ejecutar sobre el dispositivo fue necesario:
- Emparejar el dispositivo en Xcode (`Window > Devices and Simulators`)
- Activar el Modo Desarrollador en el iPhone (`Ajustes > Privacidad y
  seguridad > Modo de desarrollador`)
- Configurar la firma de código con una cuenta de Apple ID personal
  (`Signing & Capabilities > Team`, en `ios/Runner.xcworkspace`)
- Confiar en el certificado de desarrollador en el propio dispositivo
  (`Ajustes > General > VPN y administración de dispositivos`)

## Ejecución del proyecto

```bash
flutter pub get
flutter run -d <device-id>
```

El identificador del dispositivo se obtiene con:

```bash
flutter devices
```

Con la app corriendo, la recarga en caliente se activa presionando `r`
en la terminal donde se ejecuta `flutter run` (o `R` para un reinicio
completo del estado).

## Conexión con el backend

La URL base de la API se define mediante una variable de entorno de
Dart, en `lib/config.dart`:

```dart
class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.39.103:8000',
  );
}
```

Se optó por la IP local de la máquina de desarrollo (`192.168.39.103`)
en lugar de `localhost`, porque un dispositivo físico no comparte el
espacio de red del host: `localhost` en el iPhone se resuelve a sí
mismo, no a la máquina donde corre el backend. Tanto el equipo de
desarrollo como el dispositivo deben estar conectados a la misma red
Wi-Fi para que la conexión funcione.

Para sobreescribir la URL sin modificar el código (por ejemplo, si
cambia la red o la IP del equipo):

```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://NUEVA_IP:8000
```

El backend debe ejecutarse aceptando conexiones desde la red local, no
solo desde localhost:

```bash
uvicorn app.main:app --reload --host 0.0.0.0
```

### Autorización de tráfico HTTP sin cifrar

Por defecto, iOS bloquea las conexiones HTTP no cifradas (App Transport
Security). Al tratarse de un backend de desarrollo local sin HTTPS, fue
necesario declarar una excepción acotada exclusivamente a la IP del
host de desarrollo en `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>192.168.39.103</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

Esta excepción está acotada a una única IP (la del host de desarrollo)
y debe eliminarse antes de cualquier distribución de la aplicación, ya
que en producción el backend debe servirse mediante HTTPS.

## Prueba de conectividad

La pantalla principal incluye un botón que ejecuta una solicitud GET al
endpoint `/health` del backend propio y muestra la respuesta recibida en
pantalla, confirmando la comunicación exitosa entre la aplicación móvil
y la API.

## Limitaciones y dificultades encontradas

- En modo debug, iOS solo permite lanzar la aplicación desde las
  herramientas de desarrollo (terminal, IDE o Xcode); no puede abrirse
  tocando su ícono en la pantalla de inicio. Intentar hacerlo muestra un
  mensaje informativo de Flutter en lugar de la aplicación.
- El primer emparejamiento de un dispositivo físico con Xcode requiere
  pasos adicionales (extracción de símbolos de depuración, activación
  del Modo Desarrollador, confianza en el certificado) que no son
  necesarios en ejecuciones posteriores.
- La IP local del equipo de desarrollo puede cambiar entre sesiones o
  redes distintas, por lo que la URL del backend está parametrizada
  como variable de entorno en lugar de un valor fijo en el código.
