import 'dart:async';

import 'package:flutter/scheduler.dart';

abstract class PositionUpdater {
  PositionUpdater({
    required this.getPosition,
  });

  final Future<Duration?> Function() getPosition;
  final _streamController = StreamController<Duration>.broadcast();

  Stream<Duration> get positionStream => _streamController.stream;

  Future<void> update() async {
    final position = await getPosition();
    if (position != null) {
      _streamController.add(position);
    }
  }

  void start();

  Future<void> stop() async {
    await update();
  }

  Future<void> dispose() async {
    await stop();
    await _streamController.close();
  }
}

class TimerPositionUpdater extends PositionUpdater {
  Timer? _positionStreamTimer;
  final Duration interval;

  TimerPositionUpdater({
    required super.getPosition,
    required this.interval,
  });

  @override
  void start() {
    _positionStreamTimer?.cancel();
    _positionStreamTimer = Timer.periodic(interval, (timer) async {
      await update();
    });
  }

  @override
  Future<void> stop() async {
    _positionStreamTimer?.cancel();
    _positionStreamTimer = null;
    await super.stop();
  }
}

class FramePositionUpdater extends PositionUpdater {
  late int _frameCallbackId;
  bool isRunning = false;

  FramePositionUpdater({
    required super.getPosition,
  });

  void _tick(Duration? timestamp) {
    if (isRunning) {
      update();
      _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_tick);
    }
  }

  @override
  void start() {
    isRunning = true;
    _tick(null);
  }

  @override
  Future<void> stop() async {
    isRunning = false;
    SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackId);
    await super.stop();
  }
}
