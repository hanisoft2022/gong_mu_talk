import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC/Cubit 성능 최적화를 위한 mixin들
mixin ThrottleMixin {
  DateTime? _lastEmitTime;
  static const Duration _throttleDuration = Duration(milliseconds: 300);

  /// 상태 방출을 제한하여 과도한 rebuild 방지
  bool shouldEmit() {
    final now = DateTime.now();
    if (_lastEmitTime == null ||
        now.difference(_lastEmitTime!) > _throttleDuration) {
      _lastEmitTime = now;
      return true;
    }
    return false;
  }
}

/// 불필요한 rebuild를 방지하는 SelectableBuilder
class SelectableBuilder<T extends BlocBase<S>, S, R> extends StatelessWidget {
  const SelectableBuilder({
    super.key,
    required this.selector,
    required this.builder,
    this.buildWhen,
  });

  final R Function(S) selector;
  final Widget Function(BuildContext, R) builder;
  final bool Function(R previous, R current)? buildWhen;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<T, S, R>(selector: selector, builder: builder);
  }
}

/// ListView 성능 최적화를 위한 유틸리티
class OptimizedListView extends StatelessWidget {
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: EdgeInsets.zero, // 기본 패딩 제거
      // 성능 최적화 설정
      cacheExtent: 200, // 캐시 영역 확장
      addAutomaticKeepAlives: true, // 자동 keep alive
      addRepaintBoundaries: true, // repaint 경계 추가
      addSemanticIndexes: true, // 접근성 인덱스 추가
    );
  }
}

/// 메모화를 통한 성능 최적화 위젯
class MemoizedWidget extends StatelessWidget {
  const MemoizedWidget({
    super.key,
    required this.child,
    required this.dependencies,
  });

  final Widget child;
  final List<Object?> dependencies;

  @override
  Widget build(BuildContext context) {
    return _MemoizedWidgetImpl(dependencies: dependencies, child: child);
  }
}

class _MemoizedWidgetImpl extends StatefulWidget {
  const _MemoizedWidgetImpl({required this.dependencies, required this.child});

  final List<Object?> dependencies;
  final Widget child;

  @override
  State<_MemoizedWidgetImpl> createState() => _MemoizedWidgetImplState();
}

class _MemoizedWidgetImplState extends State<_MemoizedWidgetImpl> {
  late List<Object?> _previousDependencies;
  late Widget _cachedChild;

  @override
  void initState() {
    super.initState();
    _previousDependencies = List.from(widget.dependencies);
    _cachedChild = widget.child;
  }

  @override
  void didUpdateWidget(_MemoizedWidgetImpl oldWidget) {
    super.didUpdateWidget(oldWidget);

    // dependencies가 변경된 경우에만 child 업데이트
    if (!_listEquals(_previousDependencies, widget.dependencies)) {
      _previousDependencies = List.from(widget.dependencies);
      _cachedChild = widget.child;
    }
  }

  bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}

/// 성능 모니터링을 위한 프로파일러
class PerformanceProfiler {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _durations = {};

  /// 성능 측정 시작
  static void start(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// 성능 측정 종료 및 로깅
  static void end(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _durations.putIfAbsent(operation, () => []).add(duration);

      // 평균 시간이 임계값을 초과하면 경고 출력
      final durations = _durations[operation]!;
      final average = durations.reduce((a, b) => a + b) / durations.length;

      if (average > 100) {
        // 100ms 이상이면 경고
        debugPrint(
          '⚠️ Performance warning: $operation took ${duration}ms (avg: ${average.toStringAsFixed(1)}ms)',
        );
      }

      _startTimes.remove(operation);
    }
  }

  /// 성능 통계 출력
  static void printStats() {
    debugPrint('\n📊 Performance Statistics:');
    _durations.forEach((operation, durations) {
      final average = durations.reduce((a, b) => a + b) / durations.length;
      final max = durations.reduce((a, b) => a > b ? a : b);
      debugPrint(
        '$operation: avg ${average.toStringAsFixed(1)}ms, max ${max}ms, samples ${durations.length}',
      );
    });
  }
}

/// 성능 프로파일링을 위한 mixin
mixin PerformanceProfileMixin<T extends StatefulWidget> on State<T> {
  String get profileName => widget.runtimeType.toString();

  @override
  void initState() {
    PerformanceProfiler.start('$profileName.initState');
    super.initState();
    PerformanceProfiler.end('$profileName.initState');
  }

  @override
  Widget build(BuildContext context) {
    PerformanceProfiler.start('$profileName.build');
    final widget = buildProfiled(context);
    PerformanceProfiler.end('$profileName.build');
    return widget;
  }

  /// 실제 build 로직은 이 메서드에 구현
  Widget buildProfiled(BuildContext context);
}
