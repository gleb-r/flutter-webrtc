import 'dart:math';

import 'package:webrtc_interface/webrtc_interface.dart' as rtc;

import '../flutter_webrtc.dart';
import 'native/media_stream_track_impl.dart';

class MediaRecorder extends rtc.MediaRecorder {
  MediaRecorder() : _delegate = mediaRecorder();
  final rtc.MediaRecorder _delegate;

  int? _recorderId;

  @override
  Future<void> start(String path,
          {MediaStreamTrack? videoTrack, RecorderAudioChannel? audioChannel}) =>
      _delegate.start(path, videoTrack: videoTrack, audioChannel: audioChannel);

  Future<void> startWithAudio(
    String path, {
    MediaStreamTrack? videoTrack,
    RecorderAudioChannel? audioChannel,
    MediaStreamTrack? audioTrack,
    int rotationDegrees = 0,
  }) {
    return _start(
      path,
      videoTrack: videoTrack,
      audioChannel: audioChannel,
      audioTrack: audioTrack,
      rotationDegrees: rotationDegrees,
    );
  }

  Future<int> stopWithAudio() async {
    await WebRTC.invokeMethod('stopRecordToFile', {'recorderId': _recorderId});
    return _recorderId ?? 1;
  }

  @override
  Future stop() => _delegate.stop();

  Future<void> _start(
    String path, {
    MediaStreamTrack? videoTrack,
    RecorderAudioChannel? audioChannel,
    int? videoWidth,
    int? videoHeight,
    MediaStreamTrack? audioTrack,
    int rotationDegrees = 0,

    // TODO(cloudwebrtc): add codec/quality options
  }) async {
    final _random = Random();
    _recorderId = _random.nextInt(0x7FFFFFFF);
    if (audioChannel == null && videoTrack == null) {
      throw Exception('Neither audio nor video track were provided');
    }

    await WebRTC.invokeMethod('startRecordToFile', {
      'path': '$path/${_recorderId}.mp4',
      if (audioChannel != null) 'audioChannel': audioChannel.index,
      if (videoTrack != null) 'videoTrackId': videoTrack.id,
      'videoWidth': videoWidth,
      'videoHeight': videoHeight,
      if (audioTrack != null) 'audioTrackId': audioTrack.id,
      'rotation': rotationDegrees,
      'recorderId': _recorderId,
      'peerConnectionId': videoTrack is MediaStreamTrackNative
          ? videoTrack.peerConnectionId
          : null
    });
  }

  @override
  void startWeb(
    MediaStream stream, {
    Function(dynamic blob, bool isLastOne)? onDataChunk,
    String? mimeType,
    int timeSlice = 1000,
  }) =>
      _delegate.startWeb(
        stream,
        onDataChunk: onDataChunk,
        mimeType: mimeType ?? 'video/webm',
        timeSlice: timeSlice,
      );
}
