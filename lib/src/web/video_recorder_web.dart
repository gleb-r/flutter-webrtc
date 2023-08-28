import 'dart:async';
import 'dart:typed_data';

import 'package:dart_webrtc/dart_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/src/native/video_recorder/i_video_recorder.dart';
import 'package:flutter_webrtc/src/native/video_recorder/rtc_record_result.dart';

class VideoRecorder extends IVideoRecorder {
  MediaRecorder? _mediaRecorder;
  ByteBuffer? _imageBytes;
  DateTime? _recordStartTime;

  @override
  Future<bool> start({
    required String videoPath,
    required String imagePath,
    required MediaStream mediaStream,
    required String peerId,
    required bool enableAudio,
  }) async {
    if (_mediaRecorder != null) {
      debugPrint('MediaRecorder already started');
      return false;
    }
    _imageBytes =
        await mediaStream.getVideoTracks().firstOrNull?.captureFrame();
    if (_imageBytes == null) {
      debugPrint('Can\'t capture frame');
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
    return RTCRecordResult.fromBytes(
      videoPath: videoBlobUrl,
      imageBytes: _imageBytes!,
      frameRotation: 0,
      // TODO: get rotation
      detectedFrames: detectionOnVideo,
      frameInterval: 300,
      // TODO: get from detection
      durationMs: DateTime.now().difference(_recordStartTime!).inMilliseconds,
    );
  }
}
