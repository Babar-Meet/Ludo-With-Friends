import 'package:flutter/material.dart';
import '../models/game_state.dart';

class BotAI {
  static LudoToken? getBestMove(
    int playerId,
    int diceValue,
    Map<int, List<LudoToken>> playerTokens,
  ) {
    List<LudoToken> myTokens = playerTokens[playerId] ?? [];
    LudoToken? bestToken;
    int bestScore = -10000;

    // Calculate standings for leader targeting
    Map<int, int> playerScores = {};
    for (var pId in playerTokens.keys) {
      int score = 0;
      for (var t in playerTokens[pId]!) {
        if (t.isFinished) {
          score += 1000;
        } else if (!t.isHome) {
          score += t.position;
        }
      }
      playerScores[pId] = score;
    }

    var sortedScores = playerScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    int leaderId = sortedScores.isNotEmpty ? sortedScores.first.key : -1;
    int loserId = sortedScores.isNotEmpty ? sortedScores.last.key : -1;

    for (var token in myTokens) {
      int score = _evaluateMove(token, diceValue, playerId, playerTokens, leaderId, loserId);
      if (score > bestScore) {
        bestScore = score;
        bestToken = token;
      }
    }

    return bestScore > -10000 ? bestToken : null;
  }

  static int _evaluateMove(
    LudoToken token,
    int diceValue,
    int playerId,
    Map<int, List<LudoToken>> allTokens,
    int leaderId,
    int loserId,
  ) {
    if (token.isFinished) return -10000; 
    
    if (token.isHome) {
      if (diceValue == 6) {
        return 300; // Good to deploy a new token
      } else {
        return -10000; // Cannot move out of home without a 6
      }
    }

    int targetPos = token.position + diceValue;
    if (targetPos > 56) return -10000; // Overshoots home

    if (targetPos == 56) {
      return 10000; // Winning move for this token!
    }

    int score = 0;

    // Base progression: tiny bonus for advancing a token
    score += targetPos; 

    Offset? targetCoord = GameState.getCoordinate(playerId, targetPos);
    Offset? currentCoord = GameState.getCoordinate(playerId, token.position);
    
    bool targetIsSafe = targetCoord != null && GameState.safeSpots.contains(targetCoord);
    bool currentIsSafe = currentCoord != null && GameState.safeSpots.contains(currentCoord);

    int myGlobalPos = -1;
    if (token.position < 51) myGlobalPos = (token.position + playerId * 13) % 52;
    
    int myTargetGlobalPos = -1;
    if (targetPos < 51) myTargetGlobalPos = (targetPos + playerId * 13) % 52;

    // Danger checks
    bool inDangerCurrently = false;
    if (myGlobalPos != -1 && !currentIsSafe) {
      for (var pId in allTokens.keys) {
        if (pId == playerId) continue;
        for (var opToken in allTokens[pId]!) {
          if (!opToken.isHome && !opToken.isFinished && opToken.position < 51) {
            int opGlobalPos = (opToken.position + pId * 13) % 52;
            int dist = myGlobalPos - opGlobalPos;
            if (dist < 0) dist += 52;
            if (dist > 0 && dist <= 6) {
              inDangerCurrently = true;
              break;
            }
          }
        }
        if (inDangerCurrently) break;
      }
    }

    bool inDangerAtTarget = false;
    if (myTargetGlobalPos != -1 && !targetIsSafe) {
      for (var pId in allTokens.keys) {
        if (pId == playerId) continue;
        for (var opToken in allTokens[pId]!) {
          if (!opToken.isHome && !opToken.isFinished && opToken.position < 51) {
            int opGlobalPos = (opToken.position + pId * 13) % 52;
            int dist = myTargetGlobalPos - opGlobalPos;
            if (dist < 0) dist += 52;
            if (dist > 0 && dist <= 6) {
              inDangerAtTarget = true;
              break;
            }
          }
        }
        if (inDangerAtTarget) break;
      }
    }

    if (inDangerCurrently && !inDangerAtTarget) {
      score += 400; // Escaping danger is great
    } else if (!inDangerCurrently && inDangerAtTarget) {
      score -= 300; // Moving into danger is bad
    } else if (inDangerCurrently && inDangerAtTarget) {
      score -= 100; // Moving from danger to danger
    }

    // Target cell analysis (Capture & Safe spots)
    if (targetCoord != null) {
      if (targetIsSafe) {
        score += 200; // Safe spots are good
      } else {
        int opponentsOnTarget = 0;
        int maxOpponentProgress = 0;
        int capturedPlayerId = -1;
        
        for (var pId in allTokens.keys) {
          if (pId == playerId) continue;
          for (var opToken in allTokens[pId]!) {
            if (!opToken.isHome && !opToken.isFinished) {
              Offset? opCoord = GameState.getCoordinate(opToken.playerId, opToken.position);
              if (opCoord == targetCoord) {
                opponentsOnTarget++;
                capturedPlayerId = opToken.playerId;
                if (opToken.position > maxOpponentProgress) {
                  maxOpponentProgress = opToken.position;
                }
              }
            }
          }
        }
        
        if (opponentsOnTarget == 1) {
          int captureScore = 600 + (maxOpponentProgress * 10);
          
          // Leader Targeting Mechanic
          if (capturedPlayerId == leaderId) {
            captureScore += 500; // Huge bonus for capturing the leader
          } else if (capturedPlayerId == loserId) {
            captureScore -= 300; // Mercy rule: less incentive to capture the loser
          }
          
          score += captureScore;
        } else if (opponentsOnTarget > 1) {
          score -= 800; // Danger landing on multiple opponents
        }
      }
    }

    // Entering the home stretch (positions 51-55) is very good
    if (targetPos >= 51 && token.position < 51) {
      score += 300;
    }

    return score;
  }
}
