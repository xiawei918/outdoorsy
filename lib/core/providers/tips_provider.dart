import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TipsState {
  final String tip;

  TipsState({
    required this.tip,
  });

  TipsState copyWith({
    String? tip,
  }) {
    return TipsState(
      tip: tip ?? this.tip,
    );
  }
}

class TipsNotifier extends StateNotifier<TipsState> {
  TipsNotifier() : super(TipsState(
    tip: _getRandomTip(),
  ));

  static const List<String> _tips = [
    "Stay hydrated and bring water with you",
    "Try eating your lunch outside today",
    "Park a little farther away for an extra outdoor walk",
    "Take your next phone call while walking outside",
    "Do your morning stretches in the backyard or balcony",
    "Schedule a walking meeting instead of sitting in a conference room",
    "Start your day with a 5-minute outdoor meditation",
    "Set up a bird feeder and spend time watching the visitors",
    "Take a detour through a park on your way home",
    "Find a bench and read a book outside for 15 minutes",
    "Explore a new walking trail in your neighborhood",
    "Start or tend to a small garden or plant",
    "Have your morning coffee on your porch or balcony",
    "Do a quick outdoor workout circuit (even just 10 minutes)",
    "Take photos of interesting things on an outdoor walk",
    "Find a nature area and practice forest bathing for a few minutes",
  ];

  static String _getRandomTip() {
    final random = Random();
    return _tips[random.nextInt(_tips.length)];
  }

  void refreshTip() {
    state = TipsState(
      tip: _getRandomTip(),
    );
  }
}

final tipsProvider = StateNotifierProvider<TipsNotifier, TipsState>((ref) {
  return TipsNotifier();
}); 