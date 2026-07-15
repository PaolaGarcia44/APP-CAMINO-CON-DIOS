# Luz para Hoy

App catolica offline-first construida en Flutter. El nombre es provisional y
esta desacoplado en `lib/config/app_config.dart` (`AppConfig.appName`) para
poder cambiarlo sin tocar el resto del codigo.

## Estado actual

Todo el codigo Dart, el tema visual y los datos locales (`lib/` y
`assets/data/`) ya estan escritos. Lo que falta es la parte **nativa**
(carpetas `android/` e `ios/`), que este entorno no pudo generar porque no
tiene el SDK de Flutter instalado. Sigue los pasos de abajo para completarlo.

Modulos con funcionalidad real: Inicio, Biblia (lectura secuencial con
progreso, favoritos, marcadores, busqueda, tamaño de letra), Rosario guiado
(misterio del dia automatico, flechas adelante/atras, contador de cuentas,
vibracion opcional y musica de fondo offline con canto gregoriano), Oraciones
(categorias completas), Frase del dia, Reflexion diaria, Diario espiritual
(CRUD + exportar/importar), Favoritos, Musica catolica (enlaces a YouTube/
Spotify), Calendario liturgico (tiempo y color calculados por algoritmo),
Santo del dia (lista de muestra), Configuracion (tema, tamaño de letra,
vibracion, notificaciones, restablecer progreso) y notificaciones locales.

## 1. Requisitos

- Flutter SDK (canal estable, version reciente): https://docs.flutter.dev/get-started/install
- Android Studio (SDK de Android) y/o Xcode si vas a compilar para iOS.

Verifica la instalacion con:

```
flutter doctor
```

## 2. Generar las carpetas nativas (android/ios/etc.)

Este repositorio **ya tiene** `lib/`, `assets/` y `pubspec.yaml`. Para no
sobrescribir nada, genera el proyecto base en una carpeta temporal y copia
solo las carpetas nativas:

```
flutter create --org com.tuempresa --project-name luz_para_hoy temp_scaffold
```

Luego copia a la raiz de este repositorio (donde esta este README) las
carpetas generadas que aun no existen aqui: `android/`, `ios/`, y si las
necesitas, `windows/`, `macos/`, `linux/`, `web/`. **No copies** el
`pubspec.yaml` ni la carpeta `lib/` de `temp_scaffold` (sobrescribirian el
trabajo ya hecho). Cuando termines, puedes borrar `temp_scaffold`.

## 3. Instalar dependencias y ejecutar

```
flutter pub get
flutter run
```

## 4. Ajustes nativos pendientes (a mano, una sola vez)

**Android** (`android/app/src/main/AndroidManifest.xml`), dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Estos permisos son necesarios para los recordatorios diarios (notificaciones
locales). En iOS, `flutter_local_notifications` no requiere cambios extra en
Info.plist para notificaciones locales basicas.

## 5. Verificacion

Como este entorno no tiene el SDK de Flutter, el codigo no pudo compilarse
ni ejecutarse aqui. Despues de seguir los pasos anteriores, corre:

```
flutter analyze
flutter run
```

Si `flutter analyze` marca algo, lo mas probable es que sea por cambios de
API entre versiones de estos paquetes (revisa primero `flutter_local_notifications`
en `lib/data/services/notification_service.dart` y `share_plus` en las
pantallas que comparten texto, ya que son los paquetes con APIs mas
cambiantes entre versiones).

## Decisiones de arquitectura

- **Sin adaptadores de Hive generados**: favoritos, diario y progreso se
  guardan como `Map<String, dynamic>` dentro de las cajas de Hive, evitando
  `build_runner` y adaptadores generados. Ver `lib/data/models/favorite_item.dart`
  y `lib/data/models/journal_entry.dart`.
- **Repositorios solo donde hay estado real**: Biblia, Favoritos, Diario y
  Configuracion tienen interfaz de dominio (`lib/domain/repositories/`) porque
  manejan estado persistente. Oraciones, frases, reflexiones, Rosario, Santos
  y Musica son contenido de solo lectura, asi que las pantallas consumen el
  datasource directamente a traves de un provider (`lib/presentation/providers/content_providers.dart`),
  sin una capa de repositorio que no aportaria nada.
- **Texto biblico completo (dominio publico)**: la Biblia ya trae el texto
  integro de los 73 libros del canon catolico, con todos sus capitulos y
  versiculos reales. Se usa la traduccion **"Santa Biblia libre
  Latinoamericano"** (`spabll`, eBible.org), que es de **dominio publico** e
  incluye los libros deuterocanonicos (Tobias, Judit, Sabiduria, Eclesiastico,
  Baruc, 1-2 Macabeos) y las secciones griegas de Daniel (Susana, Bel y el
  Dragon) y Ester. Cada libro vive en su propio archivo
  `assets/data/bible/books/<id>.json` (`bookId`, `chapters`, con `numbers` y
  `verses`) y se carga de forma diferida. El Evangelio del dia (calendario
  liturgico) y el santoral completo siguen con estructura lista y contenido
  pendiente de ampliar.
- **Oraciones tradicionales**: la biblioteca de oraciones (`assets/data/prayers/prayers.json`)
  reune oraciones catolicas tradicionales de dominio publico (Padre Nuestro,
  Ave Maria, Credo, Salve, Memorare, oracion de San Francisco, Santo Tomas,
  etc.), organizadas por bloques tematicos.
- **Musica de fondo del Rosario (dominio publico)**: los cantos en
  `assets/audio/` provienen de "Gregorian Chant Mass" (archive.org, dominio
  publico). Se reproducen en bucle con `audioplayers` mientras se reza, con
  control de reproduccion, seleccion de canto y volumen. Todo es offline.

## Proximos pasos sugeridos

1. Generar `android/` e `ios/` (paso 2) y confirmar que compila.
2. Ampliar el santoral (`assets/data/saints/saints.json`) a los 365 dias.
3. Conectar una fuente con licencia para el Evangelio del dia.
4. Diseñar el icono de la app y la pantalla de splash nativa (hoy es una
   pantalla Flutter animada, no un splash nativo del sistema operativo).
