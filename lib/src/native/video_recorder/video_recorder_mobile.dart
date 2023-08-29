import 'dart:async';

import 'package:flutter_webrtc/src/native/video_recorder/recorder_result.dart';

import '../../../flutter_webrtc.dart';
import 'i_video_recorder.dart';

class VideoRecorder extends IVideoRecorder {
  @override
  Future<bool> start({
    required String videoPath,
    required MediaStream mediaStream,
    required bool enableAudio,
    // required bool directAudio,
  }) async {
    final isStarted = await WebRTC.invokeMethod('startRecordVideo', {
      'videoPath': videoPath,
      'streamId': mediaStream.id,
      'enableAudio': enableAudio,
      // 'directAudio': directAudio,
    });
    if (isStarted) {
      listenEventChannel();
    }
    return isStarted;
  }

  @override
  Future<RTCRecordResult> stop() async {
    super.disposeDetection();
    final resultRaw = await WebRTC.invokeMethod('stopRecordVideo');
    // TODO: listen for write complete event
    final result = RecorderResult.fromMap(resultRaw);
    final detection = detectionOnVideo;
    detection?.durationMs = result.durationMs;
    detection?.frameIntervalMs = result.frameInterval;
    detectionOnVideo = null;
    return RTCRecordResult.from(result, detection);
  }
}
