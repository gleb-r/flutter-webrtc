import 'package:equatable/equatable.dart';

class DetectionRequest extends Equatable {
  DetectionRequest(this.enabled, this.level);

  final bool enabled;
  final int? level;

  @override
  List<Object?> get props => [enabled, level];

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'level': level,
    };
  }
}
