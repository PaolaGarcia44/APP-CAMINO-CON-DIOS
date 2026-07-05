/// Devuelve el saludo segun la hora del dia.
class GreetingHelper {
  GreetingHelper._();

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Buenos dias';
    if (hour >= 12 && hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
