import 'dart:collection';
import 'dart:ui';

import 'package:equatable/equatable.dart';

class DetectionResult extends Equatable {
  DetectionResult(
      this.detectionList, this.aspectRatio, this.xCount, this.yCount);

  factory DetectionResult.fromMap(dynamic event) {
    final map = LinkedHashMap<String, dynamic>.from(event as Map);
    final List<dynamic> detected = map['detected'];
    final double aspectRatio = map['aspect'];
    final int xCount = map['xCount'];
    final int yCount = map['yCount'];
    final rectList = detected.map(Square.fromMap).toList();
    return DetectionResult(rectList, aspectRatio, xCount, yCount);
  }

  final List<Square> detectionList;
  final double aspectRatio;
  final int xCount;
  final int yCount;

  @override
  List<Object?> get props => [detectionList, aspectRatio];
}

class Square extends Equatable {
  Square(this.x, this.y);

  factory Square.fromMap(dynamic map) {
    final int x = map['x'];
    final int y = map['y'];
    return Square(x, y);
  }

  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
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
