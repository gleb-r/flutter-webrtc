import 'dart:async';

import 'package:dart_webrtc/dart_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/src/native/video_recorder/i_video_recorder.dart';
import 'package:flutter_webrtc/src/native/video_recorder/rtc_record_result.dart';

class VideoRecorder extends IVideoRecorder {
  MediaRecorder? _mediaRecorder;
  DateTime? _recordStartTime;

  @override
  Future<bool> start({
    required String videoPath,
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
    _recordStartTime = DateTime.now();
    listenEventChannel();
    return true;
  }

  @override
  Future<RTCRecordResult> stop() async {
    if (_mediaRecorder == null || _recordStartTime == null) {
      throw Exception('MediaRecorder is not started');
    }
    disposeDetection();
    final String videoBlobUrl = await _mediaRecorder?.stop();
    final duration = DateTime.now().difference(_recordStartTime!);
    return RTCRecordResult(
      videoPath: videoBlobUrl,
      frameRotation: 0,
      // TODO: get rotation
      detectedFrames: detectionOnVideo,
      frameInterval: 300,
      // TODO: get from detection
      durationMs: duration.inMilliseconds,
    );
  }
}
