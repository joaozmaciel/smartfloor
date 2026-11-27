import 'package:flutter/services.dart';

class ArMeasurementEvent {
  final String type;
  final String? trackingState;
  final String? message;
  final List<double>? position;

  const ArMeasurementEvent({
    required this.type,
    this.trackingState,
    this.message,
    this.position,
  });

  factory ArMeasurementEvent.fromMap(Map<dynamic, dynamic> map) {
    final rawPosition = map['position'];
    return ArMeasurementEvent(
      type: map['type'] as String? ?? 'unknown',
      trackingState: map['trackingState'] as String?,
      message: map['message'] as String?,
      position: rawPosition is List
          ? rawPosition.map((value) => (value as num).toDouble()).toList()
          : null,
    );
  }
}

abstract interface class ArMeasurementController {
  Stream<ArMeasurementEvent> get events;

  Future<String> checkAvailability();
  Future<bool> requestCameraPermission();
  Future<bool> requestInstall();
  Future<void> start();
  Future<void> capturePoint();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

class MethodChannelArMeasurementController
    implements ArMeasurementController {
  static const MethodChannel _methods =
      MethodChannel('smartfloor/ar_measurement');
  static const EventChannel _eventChannel =
      EventChannel('smartfloor/ar_measurement/events');

  @override
  Stream<ArMeasurementEvent> get events => _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => ArMeasurementEvent.fromMap(event as Map));

  @override
  Future<String> checkAvailability() async {
    return await _methods.invokeMethod<String>('checkAvailability') ??
        'unsupported';
  }

  @override
  Future<bool> requestCameraPermission() async =>
      await _methods.invokeMethod<bool>('requestCameraPermission') ?? false;

  @override
  Future<bool> requestInstall() async =>
      await _methods.invokeMethod<bool>('requestInstall') ?? false;

  @override
  Future<void> start() => _methods.invokeMethod<void>('start');

  @override
  Future<void> capturePoint() => _methods.invokeMethod<void>('capturePoint');

  @override
  Future<void> pause() => _methods.invokeMethod<void>('pause');

  @override
  Future<void> resume() => _methods.invokeMethod<void>('resume');

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');
}
