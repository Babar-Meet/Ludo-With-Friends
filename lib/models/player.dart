import 'package:flutter/material.dart';

class Player {
  final int id; // 0: BottomLeft, 1: TopLeft, 2: TopRight, 3: BottomRight
  final String name;
  final Color color;
  final int tokenIndex;
  
  Player({
    required this.id,
    required this.name,
    required this.color,
    required this.tokenIndex,
  });
}
