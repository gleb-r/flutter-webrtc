import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/src/native/video_recorder/record_error.dart';
import 'package:flutter_webrtc/src/native/video_recorder/record_event.dart';
import 'package:rxdart/rxdart.dart';

import '../../../flutter_webrtc.dart';
import 'i_video_recorder.dart';

class VideoRecorder extends IVideoRecorder {
  VideoRecorder({required super.onError, required super.onRecorded});

  @override
  Future<bool> start({
    required String recordId,
    required String path,
    required MediaStream mediaStream,
    required bool enableAudio,
  }) async {
    final result = await WebRTC.invokeMethod<bool, String>('startRecordVideo', {
      'recordId': recordId,
      'path': path,
      'streamId': mediaStream.id,
      'enableAudio': enableAudio,
    });
    if (result == null) {
      onError(Exception('Failed to start recording, result is null'));
    } else if (_eventsSubscription == null) {
      _listenEventChannel();
    }
    return result ?? false;
  }

  @override
  Future<void> stop() async {
    await WebRTC.invokeMethod('stopRecordVideo');
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _eventsSubscription;

  @override
  Future<void> dispose() async {
    await _eventsSubscription?.cancel();
    return super.dispose();
  }

  void _listenEventChannel() {
    _eventsSubscription = _eventChannel
        .receiveBroadcastStream()
        .doOnData((event) => print('event: $event'))
        .map((event) => RecordEvent.fromMap(event))
        .listen((event) {
      switch (event.type) {
        case RecordEventType.idle:
          stateSubject.add(RecordingState.idle);
        case RecordEventType.starting:
          stateSubject.add(RecordingState.starting);
        case RecordEventType.recording:
          stateSubject.add(RecordingState.recording);
        case RecordEventType.stop:
          stateSubject.add(RecordingState.stop);
        case RecordEventType.result:
          final result = RTCRecordResult.fromJson(event.data!);
          onRecorded(result);
        case RecordEventType.error:
          final error = RecordError.fromJson(event.data!);
          onError(error);
      }
    });
  }
}
