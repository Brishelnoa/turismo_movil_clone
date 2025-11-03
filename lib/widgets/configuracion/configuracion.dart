import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class SettingsPage2 extends StatefulWidget {
  const SettingsPage2({super.key});

  @override
  State<SettingsPage2> createState() => _SettingsPage2State();
}

class _SettingsPage2State extends State<SettingsPage2> {
  bool _isDark = false;
  // debug token shown on demand; stored locally when dialog opened if needed
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              children: [
                _SingleSection(
                  title: "General",
                  children: [
                    _CustomListTile(
                      title: "Dark Mode",
                      icon: Icons.dark_mode_outlined,
                      trailing: Switch(
                        value: _isDark,
                        onChanged: (value) {
                          setState(() {
                            _isDark = value;
                          });
                        },
                      ),
                    ),
                    const _CustomListTile(
                      title: "Notifications",
                      icon: Icons.notifications_none_rounded,
                    ),
                    _CustomListTile(
                      title: 'FCM Token (debug)',
                      icon: Icons.vpn_key_outlined,
                      trailing: TextButton(
                        child: const Text('Mostrar / Registrar'),
                        onPressed: () async {
                          // Mostrar diálogo de carga
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          String token = 'Obteniendo token...';
                          String errorDetails = '';
                          Map<String, dynamic>? serverResp;

                          try {
                            // Ensure firebase initialized
                            if (kDebugMode)
                              debugPrint(
                                  '[Settings] Ensuring Firebase initialized...');
                            await FcmService.ensureInitializedAndRegister();

                            if (kDebugMode)
                              debugPrint('[Settings] Getting FCM token...');
                            final fcmToken =
                                await FirebaseMessaging.instance.getToken();

                            if (fcmToken == null) {
                              token =
                                  'Token es null - Firebase puede no estar configurado correctamente';
                              errorDetails =
                                  'Verifica que google-services.json esté en android/app/';
                            } else {
                              token = fcmToken;
                              if (kDebugMode)
                                debugPrint(
                                    '[Settings] Token obtenido: ${token.substring(0, 20)}...');

                              // Registrar en backend
                              try {
                                if (kDebugMode)
                                  debugPrint(
                                      '[Settings] Registrando token en backend...');
                                serverResp = await FcmService
                                    .registerTokenWithBackendVerbose(token);
                                if (kDebugMode)
                                  debugPrint(
                                      '[Settings] Server response: $serverResp');
                              } catch (e) {
                                serverResp = {
                                  'success': false,
                                  'error': 'Error al registrar: ${e.toString()}'
                                };
                                if (kDebugMode)
                                  debugPrint(
                                      '[Settings] Error registrando: $e');
                              }
                            }
                          } catch (e, stackTrace) {
                            token = 'Error al obtener token';
                            errorDetails = e.toString();
                            if (kDebugMode) {
                              debugPrint('[Settings] ERROR: $e');
                              debugPrint('[Settings] Stack trace: $stackTrace');
                            }
                          }

                          // Cerrar diálogo de carga
                          if (context.mounted) Navigator.of(context).pop();

                          // Mostrar resultado
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('FCM Token (debug)'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: [
                                    const Text(
                                      'Token FCM:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      token,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (errorDetails.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Detalles del error:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        errorDetails,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                    if (serverResp != null) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Respuesta del servidor:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        'Status: ${serverResp['success'] == true ? '✅ Éxito' : '❌ Error'}\n'
                                        'Código: ${serverResp['statusCode'] ?? 'N/A'}\n'
                                        'Datos: ${serverResp['body'] ?? serverResp['error'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const _CustomListTile(
                      title: "Security Status",
                      icon: CupertinoIcons.lock_shield,
                    ),
                  ],
                ),
                const Divider(),
                const _SingleSection(
                  title: "Organization",
                  children: [
                    _CustomListTile(
                      title: "Profile",
                      icon: Icons.person_outline_rounded,
                    ),
                    _CustomListTile(
                      title: "Messaging",
                      icon: Icons.message_outlined,
                    ),
                    _CustomListTile(
                      title: "Calling",
                      icon: Icons.phone_outlined,
                    ),
                    _CustomListTile(
                      title: "People",
                      icon: Icons.contacts_outlined,
                    ),
                    _CustomListTile(
                      title: "Calendar",
                      icon: Icons.calendar_today_rounded,
                    ),
                  ],
                ),
                const Divider(),
                _SingleSection(
                  children: [
                    const _CustomListTile(
                      title: "Help & Feedback",
                      icon: Icons.help_outline_rounded,
                    ),
                    const _CustomListTile(
                      title: "About",
                      icon: Icons.info_outline_rounded,
                    ),
                    _CustomListTile(
                      title: "Sign out",
                      icon: Icons.exit_to_app_rounded,
                      onTap: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _CustomListTile({
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SingleSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Column(children: children),
      ],
    );
  }
}
