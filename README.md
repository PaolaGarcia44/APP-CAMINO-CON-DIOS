# Luz para Hoy

App catolica offline-first construida en Flutter (Material 3, Riverpod,
go_router y Hive). Sin Firebase, sin servidor y sin servicios de pago: todo
el contenido y la configuracion viven en el telefono. El nombre esta
desacoplado en `lib/config/app_config.dart` (`AppConfig.appName`).

## Modulos

- **Inicio**: saludo segun la hora, tiempo liturgico del dia, fecha especial
  (si la hay), mensaje del dia, continuar la lectura biblica, proximas tareas
  y reflexion del dia.
- **Biblia** completa (73 libros): continuar donde quedaste, plan en orden,
  capitulos leidos, historial, marcadores de capitulo y de versiculo,
  favoritos, compartir/copiar versiculos, busqueda por libro, capitulo,
  versiculo ("Jn 3:16") y por palabras dentro del texto, tamaño de letra y
  modo de lectura sepia.
- **Agenda**: tareas con fecha, hora, descripcion, recordatorio y repeticion
  (no repetir, diaria, semanal, mensual); vista por dia con calendario
  mensual/semanal, proximas, pendientes y completadas.
- **Oraciones** (mas de 400, por categorias) con oracion del dia.
- **Mas**: Calendario catolico, Reflexiones, Favoritos, Diario espiritual,
  Santo del dia, Musica catolica y Configuracion.

## Ejecutar y compilar

```
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. La version
release se firma con las llaves de depuracion (ver `android/app/build.gradle.kts`);
para publicar en Play Store hay que configurar una llave propia.

## Notificaciones locales

`flutter_local_notifications` + `timezone` programan todo en el telefono:

| Aviso | Por defecto | Canal Android |
|---|---|---|
| Mensaje del dia | 7:00, activo | `luz_daily_message` |
| Recordatorio de lectura | 20:00, activo | `luz_bible_reading` |
| Reflexion diaria | 17:00, inactivo | `luz_reflection` |
| Fechas especiales | 8:00, activo | `luz_special_dates` |
| Recordatorios de Agenda | segun cada tarea | `luz_agenda` |

El interruptor general empieza apagado; al activarlo se pide el permiso del
sistema. El mensaje del dia cambia cada dia, por eso se programan avisos para
los proximos 30 dias y la ventana se renueva cada vez que se abre la app o
cambia el dia. Los avisos sobreviven a reinicios gracias a los receptores
declarados en `AndroidManifest.xml` (y a las reglas de `android/app/proguard-rules.pro`).
Los recordatorios de Agenda usan alarma exacta si el usuario la permite
(Configuracion → Notificaciones); si no, pueden llegar con unos minutos de margen.

La logica de "que programar" es pura y esta probada en
`lib/domain/usecases/notification_planner.dart`; `lib/data/services/notification_service.dart`
solo la traduce al plugin.

## Contenido y como actualizarlo

- **Biblia**: "Santa Biblia libre Latinoamericano" (`spabll`, eBible.org),
  **dominio publico**, con deuterocanonicos y las secciones griegas de Daniel
  y Ester. Un archivo por libro en `assets/data/bible/books/<id>.json`
  (`{bookId, chapters:[{chapterNumber, numbers, verses}]}`) mas
  `books_index.json`. Para cambiar de traduccion basta con regenerar esos
  archivos con la misma forma (y una licencia que lo permita).
- **Mensajes del dia**: `assets/data/quotes/quotes.json` (`id`, `text`,
  `category` y, en los versiculos, `reference`). Los versiculos se copiaron
  literalmente de la Biblia de dominio publico de la app. Se elige uno por dia
  sin repetir hasta agotar la lista y nunca el mismo dos dias seguidos
  (`lib/core/utils/daily_selector.dart`).
- **Calendario catolico**: las celebraciones de fecha fija estan en
  `assets/data/calendar/celebrations.json` (con `version`, `rank`, `color`,
  `region` y reglas de traslado). Las moviles (Ceniza, Semana Santa, Pascua,
  Ascension, Pentecostes, Corpus, Cristo Rey, Adviento...) se calculan en
  `lib/domain/usecases/catholic_calendar.dart`. Epifania, Ascension y Corpus
  se celebran en domingo, como en Colombia. Para actualizar el calendario se
  edita el JSON; no hace falta tocar codigo.
- **Santos**: `assets/data/saints/saints.json` (historia, frase y oracion).
- **Oraciones** y **reflexiones**: `assets/data/prayers/` y `assets/data/reflections/`.

## Decisiones de arquitectura

- **Capas**: `lib/domain` (entidades, interfaces de repositorio y casos de
  uso puros), `lib/data` (datasources de assets, repositorios Hive, servicio
  de notificaciones) y `lib/presentation` (providers Riverpod y pantallas).
- **Hive sin adaptadores generados**: todo se guarda como `Map` o tipos
  primitivos (sin `build_runner`). Cajas en `lib/core/constants/hive_boxes.dart`.
- **Repositorios solo donde hay estado real**: Biblia (progreso, historial,
  marcadores), Agenda, Favoritos, Diario y Configuracion. El contenido de solo
  lectura se consume desde su datasource.
- **Reiniciar progreso biblico** borra plan, capitulos leidos, historial y
  ultima posicion, pero conserva favoritos, marcadores, tareas y diario.
