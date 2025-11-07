import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class JudgeLine extends RectangleComponent {
  JudgeLine({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          paint: Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..strokeWidth = 3,
        );

  void showHitEffect() {
    paint.color = Colors.yellow;
    Future.delayed(const Duration(milliseconds: 100), () {
      paint.color = Colors.white.withValues(alpha: 0.8);
    });
  }
}