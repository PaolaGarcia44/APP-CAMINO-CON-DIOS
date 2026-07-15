import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Una pista de musica de fondo para el Rosario. `asset` es la ruta relativa
/// a la carpeta `assets/` (audioplayers antepone `assets/` automaticamente).
class RosaryTrack {
  final String title;
  final String asset;
  const RosaryTrack(this.title, this.asset);
}

/// Cantos gregorianos de dominio publico incluidos en la app
/// (Gregorian Chant Mass, archive.org, dominio publico).
const kRosaryTracks = <RosaryTrack>[
  RosaryTrack('Canto gregoriano I', 'audio/canto_gregoriano_1.mp3'),
  RosaryTrack('Canto gregoriano II', 'audio/canto_gregoriano_2.mp3'),
  RosaryTrack('Canto gregoriano III', 'audio/canto_gregoriano_3.mp3'),
];

class RosaryMusicState {
  final bool isPlaying;
  final int trackIndex;
  final double volume;

  const RosaryMusicState({
    this.isPlaying = false,
    this.trackIndex = 0,
    this.volume = 0.5,
  });

  RosaryTrack get track => kRosaryTracks[trackIndex];

  RosaryMusicState copyWith({bool? isPlaying, int? trackIndex, double? volume}) {
    return RosaryMusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      trackIndex: trackIndex ?? this.trackIndex,
      volume: volume ?? this.volume,
    );
  }
}

/// Controla la reproduccion de la musica de fondo del Rosario. La pista se
/// repite en bucle mientras se reza; el usuario puede pausar, cambiar de
/// canto y ajustar el volumen.
class RosaryMusicNotifier extends StateNotifier<RosaryMusicState> {
  RosaryMusicNotifier() : super(const RosaryMusicState()) {
    _player.setReleaseMode(ReleaseMode.loop);
    _sub = _player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (mounted && playing != state.isPlaying) {
        state = state.copyWith(isPlaying: playing);
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  late final dynamic _sub;

  Future<void> play() async {
    try {
      await _player.play(AssetSource(state.track.asset), volume: state.volume);
      if (mounted) state = state.copyWith(isPlaying: true);
    } catch (_) {
      // Si el audio no se puede reproducir (p. ej. plataforma sin soporte),
      // se ignora silenciosamente para no interrumpir el rezo.
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    if (mounted) state = state.copyWith(isPlaying: false);
  }

  Future<void> toggle() => state.isPlaying ? pause() : play();

  /// Selecciona una pista y la reproduce de inmediato (usado al tocar un
  /// canto en la lista).
  Future<void> playTrack(int index) async {
    if (index < 0 || index >= kRosaryTracks.length) return;
    if (index != state.trackIndex) {
      state = state.copyWith(trackIndex: index);
      try {
        await _player.stop();
      } catch (_) {}
    }
    await play();
  }

  Future<void> setVolume(double value) async {
    final vol = value.clamp(0.0, 1.0);
    state = state.copyWith(volume: vol);
    try {
      await _player.setVolume(vol);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub.cancel();
    _player.dispose();
    super.dispose();
  }
}

final rosaryMusicProvider =
    StateNotifierProvider<RosaryMusicNotifier, RosaryMusicState>(
  (ref) => RosaryMusicNotifier(),
);
