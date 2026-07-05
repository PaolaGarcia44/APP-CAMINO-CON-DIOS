/// Configuracion global de la app, desacoplada para poder
/// renombrar o re-marcar la aplicacion sin tocar el resto del codigo.
class AppConfig {
  AppConfig._();

  static const String appName = 'Luz para Hoy';
  static const String appTagline = 'Un momento con Dios, cada dia';
  static const String appVersion = '0.1.0';

  /// Prefijo usado por Hive para cajas y por notificaciones locales.
  static const String storageNamespace = 'luz_para_hoy';
}
