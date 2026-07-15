import 'package:flutter/material.dart';

class GameState {
  static const List<Offset> globalPath = [
    // 0..12
    Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),
    Offset(5, 8), Offset(4, 8), Offset(3, 8), Offset(2, 8), Offset(1, 8), Offset(0, 8),
    Offset(0, 7), Offset(0, 6),
    // 13..25
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),
    Offset(6, 5), Offset(6, 4), Offset(6, 3), Offset(6, 2), Offset(6, 1), Offset(6, 0),
    Offset(7, 0), Offset(8, 0),
    // 26..38
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),
    Offset(9, 6), Offset(10, 6), Offset(11, 6), Offset(12, 6), Offset(13, 6), Offset(14, 6),
    Offset(14, 7), Offset(14, 8),
    // 39..51
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
    Offset(8, 9), Offset(8, 10), Offset(8, 11), Offset(8, 12), Offset(8, 13), Offset(8, 14),
    Offset(7, 14), Offset(6, 14),
  ];

  static const List<List<Offset>> homePaths = [
    // Player 0 (Blue)
    [Offset(7, 13), Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9)],
    // Player 1 (Red)
    [Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7)],
    // Player 2 (Green)
    [Offset(7, 1), Offset(7, 2), Offset(7, 3), Offset(7, 4), Offset(7, 5)],
    // Player 3 (Yellow)
    [Offset(13, 7), Offset(12, 7), Offset(11, 7), Offset(10, 7), Offset(9, 7)],
  ];

  static const List<Offset> safeSpots = [
    Offset(6, 13), Offset(1, 6), Offset(8, 1), Offset(13, 8), // Starts
    Offset(2, 8), Offset(6, 2), Offset(12, 6), Offset(8, 12), // Stars
  ];

  // Helper to get exact coordinate for a token
  static Offset? getCoordinate(int playerIndex, int position) {
    if (position < 0) return null; // Inside base home
    if (position >= 56) return null; // Finished
    
    if (position < 51) {
      // Outer path
      int offset = playerIndex * 13;
      int globalIndex = (position + offset) % 52;
      return globalPath[globalIndex];
    } else {
      // Home path (51, 52, 53, 54, 55)
      int homeIndex = position - 51;
      return homePaths[playerIndex][homeIndex];
    }
  }
}

class LudoToken {
  final int id;
  final int playerId;
  int position; // -1 means home base, 0 is start cell, 56 is finished
  
  LudoToken({required this.id, required this.playerId, this.position = -1});

  bool get isHome => position == -1;
  bool get isFinished => position == 56;
}
