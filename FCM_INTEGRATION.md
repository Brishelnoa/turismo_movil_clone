# Integración FCM — Cliente Flutter (resumen para este repo)

Este documento resume los cambios realizados y los pasos para configurar FCM con el backend Django descrito en tu guía.

Cambios realizados en este repositorio:

- Se añadieron dependencias en `pubspec.yaml`:
  - `firebase_core`
  - `firebase_messaging`

- Nuevo fichero: `lib/services/fcm_service.dart`
  - Inicializa Firebase, registra handlers (foreground/background), obtiene token FCM, y llama al endpoint `/api/fcm-dispositivos/registrar/` usando el token DRF almacenado en `flutter_secure_storage`.
  - Reintenta el registro cuando el token se refresca.

- `lib/main.dart` actualizado para invocar `FcmService.init()` antes de `runApp()` (no bloqueante — continúa si falla).

- `lib/services/auth_service.dart` actualizado para intentar enviar el token FCM al backend justo después de un login exitoso.

Notas importantes / pasos de configuración

1. Android native files
   - Descarga `google-services.json` desde Firebase Console y colócalo en `android/app/`.
   - Asegúrate de seguir la guía oficial de Firebase para Android (añadir plugin en `android/build.gradle`, etc.).
   - En desarrollo, `android:usesCleartextTraffic="true"` ya está presente en `AndroidManifest.xml` para permitir conexiones HTTP al backend local. En producción NUNCA uses cleartext.

2. Backend (Django)
   - Debes tener el `service account` JSON y la variable de entorno `RUTA_CUENTA_SERVICIO_FIREBASE` apuntando a su ruta en el servidor donde corre Django.
   - `firebase-admin` debe estar instalado en el entorno virtual del backend.
   - El endpoint POST `/api/fcm-dispositivos/registrar/` debe existir y requerir autenticación (TokenAuthentication). La app enviará JSON: `{ "registration_id": "<FCM_TOKEN>", "tipo_dispositivo": "android", "nombre": "<device_name>" }`.

3. Flujo esperado en la app
   - La app inicializa Firebase en `main()` y obtiene el token FCM.
   - Si ya hay un usuario autenticado (token DRF en `flutter_secure_storage`), la app intentará registrar el token con el backend inmediatamente.
   - Después del login, `AuthService.login` intentará también registrar el token si no lo estaba antes.

4. Pruebas rápidas
   - Con el backend en la LAN (ej. `http://192.168.0.13:8000`): asegúrate `BASE_URL` en `.env` o usando `--dart-define` apunte a la IP del PC.
   - Si usas USB y `127.0.0.1:8000`, ejecuta `adb reverse tcp:8000 tcp:8000`.
   - Inicia la app; haz login; verifica que en Django admin/table `FCMDevice` aparece el token.
   - Envía notificación de prueba desde backend (usando `enviar_tokens_push`) y comprueba que el dispositivo recibe la notificación.

5. Notas y limitaciones
   - Si el usuario no está logueado al iniciar la app, la primera obtención del token no se registrará hasta que haya un token DRF válido. Por eso `AuthService.login` intenta re-enviar el token.
   - Para obtener un nombre de dispositivo más amigable, puedes añadir `device_info_plus` y enviar `deviceInfo.product`/`model`.

Si quieres, puedo:
- Migrar más servicios para usar plenamente `network.dart` (ya empecé con varias) y asegurar que los headers de registro FCM son correctos para JWT vs TokenAuth.
- Añadir un pequeño botón en la UI (p. ej. en `widgets/configuracion`) para "Registrar token FCM ahora" y mostrar el token en pantalla para debugging.
- Generar un snippet de management command en Django para enviar notificaciones de prueba a un usuario.

Si quieres que aplique alguno de los extras, dime cuál y lo implemento.
