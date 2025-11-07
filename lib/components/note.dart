import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Note extends RectangleComponent {
  final int lane;
  final int hitTime;
  final int? endTime;
  final double speed;
  bool isHit = false;
  bool isMissed = false;

  Note({
    required this.lane,
    required this.hitTime,
    this.endTime,
    required this.speed,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = Colors.blue,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;

    if (position.y > 1000 && !isHit) {
      isMissed = true;
    }
  }

  bool get isLongNote => endTime != null;

  double get duration => isLongNote ? (endTime! - hitTime) / 1000.0 : 0;
}