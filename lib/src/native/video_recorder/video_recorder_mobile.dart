import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/src/native/video_recorder/record_error.dart';
import 'package:flutter_webrtc/src/native/video_recorder/record_event.dart';
import 'package:flutter_webrtc/src/native/video_recorder/record_state.dart';
import 'package:rxdart/subjects.dart';

import '../../../flutter_webrtc.dart';
import 'i_video_recorder.dart';

class VideoRecorder extends IVideoRecorder {
  VideoRecorder({required super.onError, required super.onRecorded}) {
    _listenEventChannel();
  }

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
    }
    return result ?? false;
  }

  @override
  Future<void> stop() async {
     await WebRTC.invokeMethod('stopRecordVideo');
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _detectionSubscription;
  final _stateSubject = BehaviorSubject.seeded(RecordState.idle);

  @override
  Future<void> dispose() async {
    if (_stateSubject.value.isRecording) {
      await stop();
    }
    await _detectionSubscription?.cancel();
    await _stateSubject.close();

  }

  void _listenEventChannel() {
    _detectionSubscription = _eventChannel
        .receiveBroadcastStream()
        .map((json) => RecordEvent.fromJson(json))
        .listen((event) {
          switch (event.type) {
            case RecordEventType.idle:
              _stateSubject.add(RecordState.idle);
            case RecordEventType.starting:
              _stateSubject.add(RecordState.starting);
            case RecordEventType.recording:
              _stateSubject.add(RecordState.recording);
            case RecordEventType.stop:
              _stateSubject.add(RecordState.stop);
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
  Stream<RecordState> get recordStateStream => _stateSubject.stream;
}
