import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Lane extends RectangleComponent {
  final int laneIndex;

  Lane({
    required this.laneIndex,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          paint: Paint()
            ..color = Colors.grey.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
}