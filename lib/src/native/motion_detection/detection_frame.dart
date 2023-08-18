import 'package:equatable/equatable.dart';

class DetectionFrame extends Equatable {
  const DetectionFrame(
      this.detectionList, this.aspectRatio, this.xCount, this.yCount);

  factory DetectionFrame.fromMap(dynamic event) {
    final map = Map<String, dynamic>.from(event as Map);
    final List<dynamic> detected = map['detected'];
    final double aspectRatio = map['aspect'];
    final int xCount = map['xCount'];
    final int yCount = map['yCount'];
    final List<Square> rectList = detected.map((sq) => Square.fromString(sq)).toList();
    return DetectionFrame(rectList, aspectRatio, xCount, yCount);
  }

  factory DetectionFrame.empty() => DetectionFrame(const [], 1, 1, 1);

  final List<Square> detectionList;
  final double aspectRatio;
  final int xCount;
  final int yCount;

  @override
  List<Object?> get props => [detectionList, aspectRatio];
}

class Square extends Equatable {
  Square(this.x, this.y);

  factory Square.fromString(dynamic string) {
    final list = (string as String).split(':');
    if (list.length != 2) {
      throw Exception('Wrong square parse: $string');
    }
    return Square(int.parse(list[0]), int.parse(list[1]));
  }

  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
}
