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
    required String dirPath,
    required MediaStream mediaStream,
    required bool enableAudio,
  }) async {
    final result = await WebRTC.invokeMethod<bool, String>('startRecordVideo', {
      'dirPath': dirPath,
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
  final _stateSubject = BehaviorSubject.seeded(RecordingState.idle);

  @override
  Future<void> dispose() async {
    if (_stateSubject.value.isRecording) {
      await stop();
    }
    await _eventsSubscription?.cancel();
    await _stateSubject.close();

  }

  void _listenEventChannel() {
    _eventsSubscription = _eventChannel
        .receiveBroadcastStream()
        .doOnData((event) => print('event: $event'))
        .map((json) => RecordEvent.fromMap(json))
        .listen((event) {
          switch (event.type) {
            case RecordEventType.idle:
              _stateSubject.add(RecordingState.idle);
            case RecordEventType.starting:
              _stateSubject.add(RecordingState.starting);
            case RecordEventType.recording:
              _stateSubject.add(RecordingState.recording);
            case RecordEventType.stop:
              _stateSubject.add(RecordingState.stop);
            case RecordEventType.result:
              final result = RTCRecordResult.fromJson(event.data!);
              onRecorded(result);
            case RecordEventType.error:
              final error = RecordError.fromJson(event.data!);
              onError(error);
          }
    });
  }

  @override
  Stream<RecordingState> get recordStateStream => _stateSubject.stream;

  @override
  RecordingState get currentState => _stateSubject.value;
}
