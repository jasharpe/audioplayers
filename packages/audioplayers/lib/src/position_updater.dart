import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/scheduler.dart';

abstract class PositionUpdater {
  PositionUpdater({
    required this.getPosition,
    required this.getState,
  });

  final Future<Duration?> Function() getPosition;
  final PlayerState Function() getState;
  final _streamController = StreamController<Duration>.broadcast();

  Stream<Duration> get positionStream => _streamController.stream;

  Future<void> updateOnPlay() async {
    if (getState() == PlayerState.playing) {
      await update();
    }
  }

  Future<void> update() async {
    final position = await getPosition();
    if (position != null) {
      _streamController.add(position);
    }
  }

  Future<void> dispose() async {
    await _streamController.close();
  }
}

class TimerPositionUpdater extends PositionUpdater {
  late final Timer _positionStreamTimer;

  TimerPositionUpdater({
    required super.getPosition,
    required super.getState,
    required Duration interval,
  }) {
    _positionStreamTimer = Timer.periodic(interval, (timer) async {
      await updateOnPlay();
    });
  }

  @override
  Future<void> dispose() async {
    _positionStreamTimer.cancel();
    await super.dispose();
  }
}

class FramePositionUpdater extends PositionUpdater {
  late int _frameCallbackId;
  bool isRunning = true;

  FramePositionUpdater({
    required super.getPosition,
    required super.getState,
  }) {
    _tick(null);
  }

  void _tick(Duration? timestamp) {
    if (isRunning) {
      updateOnPlay();
      _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_tick);
    }
  }

  @override
  Future<void> dispose() async {
    isRunning = false;
    SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackId);
    await super.dispose();
  }
}
