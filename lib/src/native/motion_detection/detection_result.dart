import 'dart:collection';
import 'dart:ui';

import 'package:equatable/equatable.dart';

class DetectionResult extends Equatable {
  DetectionResult(this.detectionList, this.aspectRatio);

  factory DetectionResult.fromMap(dynamic event) {
    final map = LinkedHashMap<String, dynamic>.from(event as Map);
    final List<dynamic> detected = map['detected'];
    final double aspectRatio = map['aspect'];
    final rectList = detected.map(LumaRect.fromMap).toList();
    return DetectionResult(rectList, aspectRatio);
  }

  final List<LumaRect> detectionList;
  final double aspectRatio;

  @override
  List<Object?> get props => [detectionList, aspectRatio];
}

class LumaRect extends Equatable {
  LumaRect(this.rect, this.color);

  factory LumaRect.fromMap(dynamic object) {
    final map = LinkedHashMap<String, dynamic>.from(object);
    final double left = map['l'];
    final double top = map['t'];
    final double right = map['r'];
    final double bottom = map['b'];
    final int color = map['c'];

    final rect = Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );
    return LumaRect(rect, color);
  }

  final Rect rect;
  final int color;

  @override
  List<Object?> get props => [rect, color];
}
