import 'package:flutter/foundation.dart';

class LifeScrollCoordinator {
  LifeScrollCoordinator._();

  static final LifeScrollCoordinator instance = LifeScrollCoordinator._();

  final ValueNotifier<int> _ticker = ValueNotifier<int>(0);

  void requestScrollToTop() {
    _ticker.value++;
  }

  void addListener(VoidCallback listener) {
    _ticker.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    _ticker.removeListener(listener);
  }

  int get lastRequestId => _ticker.value;
}
