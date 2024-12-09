import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

import '../helper.dart';
import 'utils.dart';

class MediaStreamTrackNative extends MediaStreamTrack {
  MediaStreamTrackNative(this._trackId, this._label, this._kind, this._enabled,
      this._peerConnectionId,
      [this.settings_ = const {}]);

  factory MediaStreamTrackNative.fromMap(
      Map<dynamic, dynamic> map, String peerConnectionId) {
    return MediaStreamTrackNative(map['id'], map['label'], map['kind'],
        map['enabled'], peerConnectionId, map['settings'] ?? {});
  }

  final String _trackId;
  final String _label;
  final String _kind;
  final String _peerConnectionId;
  final Map<Object?, Object?> settings_;

  Map<String, dynamic>? _mediaConstraints;

  bool _enabled;

  bool _muted = false;

  String get peerConnectionId => _peerConnectionId;

  @override
  set enabled(bool enabled) {
    WebRTC.invokeMethod('mediaStreamTrackSetEnable', <String, dynamic>{
      'trackId': _trackId,
      'enabled': enabled,
      'peerConnectionId': _peerConnectionId
    });
    _enabled = enabled;

    if (kind == 'audio') {
      _muted = !enabled;
      muted ? onMute?.call() : onUnMute?.call();
    }
  }

  @override
  bool get enabled => _enabled;

  @override
  String get label => _label;

  @override
  String get kind => _kind;

  @override
  String get id => _trackId;

  @override
  bool get muted => _muted;

  @override
  Future<bool> hasTorch() => WebRTC.invokeMethod(
        'mediaStreamTrackHasTorch',
        <String, dynamic>{'trackId': _trackId},
      ).then((value) => value ?? false);

  @override
  Future<void> setTorch(bool torch) => WebRTC.invokeMethod(
        'mediaStreamTrackSetTorch',
        <String, dynamic>{'trackId': _trackId, 'torch': torch},
      );

  Future<void> setCustomExposure({
    required bool enable,
    required int durationMs,
    required int iso,
    required bool ultraBrightness,
  }) =>
      WebRTC.invokeMethod(
        'mediaStreamTrackSetCustomExposure',
        <String, dynamic>{
          'trackId': _trackId,
          'enable': enable,
          'ultraBrightness': ultraBrightness,
          'durationMs': durationMs,
          'iso': iso,
        },
      );

  @override
  Future<bool> switchCamera() => Helper.switchCamera(this);

  Future<void> setZoom(double zoomLevel) => Helper.setZoom(this, zoomLevel);

  Future<void> setContinuousExposure(bool enable) {
    return WebRTC.invokeMethod(
      'enableContinuousExposure',
      <String, dynamic>{'trackId': _trackId, 'enable': enable},
    );
  }

  @Deprecated('Use Helper.setSpeakerphoneOn instead')
  @override
  void enableSpeakerphone(bool enable) async {
    return Helper.setSpeakerphoneOn(enable);
  }

  @override
  Future<ByteBuffer> captureFrame() async {
    var filePath = await getTemporaryDirectory();
    await WebRTC.invokeMethod(
      'captureFrame',
      <String, dynamic>{
        'trackId': _trackId,
        'peerConnectionId': _peerConnectionId,
        'path': '${filePath.path}/captureFrame.png'
      },
    );
    return File('${filePath.path}/captureFrame.png')
        .readAsBytes()
        .then((value) => value.buffer);
  }

  @override
  Future<void> applyConstraints([Map<String, dynamic>? constraints]) async {
    if (constraints == null) return Future.value();

    final current = _mediaConstraints;
    if (constraints.containsKey('volume') &&
        current?['volume'] != constraints['volume']) {
      Helper.setVolume(constraints['volume'], this);
    } else if (constraints['video']?['mandatory'] != null) {
      final Map<String, dynamic> nextMandatory =
          constraints['video']['mandatory'];
      final Map<String, dynamic>? currentMandatory =
          current?['video']?['mandatory'];
      final nextWidth = nextMandatory['minWidth'];
      final nextHeight = nextMandatory['minHeight'];
      final nextFrameRate = nextMandatory['minFrameRate'];
      if (nextWidth != null && nextWidth != currentMandatory?['minWidth'] ||
          nextHeight != null && nextHeight != currentMandatory?['minHeight'] ||
          nextFrameRate != null &&
              nextFrameRate != currentMandatory?['minFrameRate']) {
        _changeVideoResolution(
          trackId: _trackId,
          width: int.parse(nextWidth),
          height: int.parse(nextHeight),
          fps: int.parse(nextFrameRate),
        );
      }
    }
    _mediaConstraints = constraints;
    return Future.value();
  }

  void _changeVideoResolution({
    required String trackId,
    required int width,
    required int height,
    required int fps,
  }) =>
      WebRTC.invokeMethod(
        'changeVideoResolution',
        <String, dynamic>{
          'width': width,
          'height': height,
          'fps': fps,
          'trackId': trackId,
        },
      );

  @override
  Map<String, dynamic> getSettings() {
    return settings_.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<void> dispose() async {
    return stop();
  }

  @override
  Future<void> stop() async {
    await WebRTC.invokeMethod(
      'trackDispose',
      <String, dynamic>{'trackId': _trackId},
    );
  }
}
