import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  ThemeModeNotifier(this.ref) : super(ref.read(settingsRepositoryProvider).getThemeMode());

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);

class FontScaleNotifier extends StateNotifier<double> {
  final Ref ref;
  FontScaleNotifier(this.ref) : super(ref.read(settingsRepositoryProvider).getFontScale());

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(0.8, 1.6);
    state = clamped;
    await ref.read(settingsRepositoryProvider).setFontScale(clamped);
  }
}

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>(
  (ref) => FontScaleNotifier(ref),
);

class BoolSettingNotifier extends StateNotifier<bool> {
  final Ref ref;
  final bool Function() reader;
  final Future<void> Function(bool) writer;

  BoolSettingNotifier(this.ref, this.reader, this.writer) : super(reader());

  Future<void> toggle(bool value) async {
    state = value;
    await writer(value);
  }
}

final vibrationEnabledProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return BoolSettingNotifier(ref, repo.getVibrationEnabled, repo.setVibrationEnabled);
});

final notificationsEnabledProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return BoolSettingNotifier(ref, repo.getNotificationsEnabled, repo.setNotificationsEnabled);
});

final onboardingSeenProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return BoolSettingNotifier(ref, repo.getOnboardingSeen, repo.setOnboardingSeen);
});
