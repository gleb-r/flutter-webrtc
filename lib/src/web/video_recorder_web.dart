import 'dart:async';

import 'package:dart_webrtc/dart_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/src/native/video_recorder/i_video_recorder.dart';
import 'package:flutter_webrtc/src/native/video_recorder/recording_state.dart';
import 'package:flutter_webrtc/src/native/video_recorder/rtc_record_result.dart';

class VideoRecorder extends IVideoRecorder {
  VideoRecorder({required super.onError, required super.onRecorded});

  MediaRecorder? _mediaRecorder;
  DateTime? _recordStartTime;
  String? _recordId;

  @override
  Future<bool> start({
    required String recordId,
    required String path,
    required MediaStream mediaStream,
    required bool enableAudio,
  }) async {
    if (_mediaRecorder != null) {
      debugPrint('MediaRecorder already started');
      return false;
    }
    _mediaRecorder = MediaRecorder();
    _mediaRecorder?.startWeb(
      mediaStream,
      mimeType: "video/webm",
    );
    _recordId = recordId;
    _recordStartTime = DateTime.now();
    stateSubject.add(RecordingState.recording);
    return true;
  }

  @override
  Future<void> stop() async {
    if (_mediaRecorder == null || _recordStartTime == null) {
      throw Exception('MediaRecorder is not started');
    }
    final recordId = _recordId;
    if (recordId == null) {
      throw Exception('RecordId is not set');
    }
    stateSubject.add(RecordingState.stop);
    final String videoBlobUrl = await _mediaRecorder?.stop();
    final duration = DateTime.now().difference(_recordStartTime!);
    onRecorded(RTCRecordResult(
      recordId: recordId,
      videoPath: videoBlobUrl,
      frameRotation: 0,
      // TODO: get rotation
      detection: detectionOnVideo,
      // TODO: get from detection
      durationMs: duration.inMilliseconds,
    ));
    _mediaRecorder = null;
    _recordStartTime = null;
    stateSubject.add(RecordingState.idle);
  }

}
