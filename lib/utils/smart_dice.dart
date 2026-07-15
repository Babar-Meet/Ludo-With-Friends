import 'dart:math';
import 'dart:ui';
import '../models/game_state.dart';

class SmartDice {
  static final Random _random = Random();

  /// Rolls the dice, potentially biasing the outcome based on game state
  /// to provide a better AI experience and catch-up mechanics.
  static int roll(int playerId, Map<int, List<LudoToken>> playerTokens, {bool isBot = false}) {
    int baseRoll = _determineBaseRoll(playerId, playerTokens, isBot);
    return _applyKillRig(playerId, baseRoll, playerTokens);
  }

  static int _determineBaseRoll(int playerId, Map<int, List<LudoToken>> playerTokens, bool isBot) {
    int activeTokens = 0;
    int tokensInHome = 0;
    int finishedTokens = 0;

    List<LudoToken> myTokens = playerTokens[playerId] ?? [];
    for (var token in myTokens) {
      if (token.isHome) {
        tokensInHome++;
      } else if (token.isFinished) {
        finishedTokens++;
      } else {
        activeTokens++;
      }
    }

    // Calculate standings for Catch-up mechanics (Rubber-banding)
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

    // Is current player in last place?
    bool isLosing = (playerId == loserId && sortedScores.length > 1);
    // Is current player in first place?
    bool isWinning = (playerId == leaderId && sortedScores.length > 1);

    // --- Catch-Up Mechanics (Rubber-Banding) ---
    if (isLosing) {
      // 1. High priority: If losing and completely stuck, give a high chance for a 6
      if (activeTokens == 0 && tokensInHome > 0) {
        if (_random.nextDouble() < 0.35) { // 35% chance of 6 (boosted from 28%)
          return 6;
        }
      }

      // 2. Medium priority: If losing and have tokens in home, slightly boost 6
      if (tokensInHome > 0) {
        if (_random.nextDouble() < 0.25) { // 25% chance of 6 (boosted from 20%)
          return 6;
        }
      }
      
      // 3. Exact capture roll logic for loser
      for (var token in myTokens) {
        if (token.isHome || token.isFinished) continue;
        int myGlobalPos = (token.position + playerId * 13) % 52;

        for (var pId in playerTokens.keys) {
          if (pId == playerId) continue;
          for (var opToken in playerTokens[pId]!) {
            if (!opToken.isHome && !opToken.isFinished && opToken.position < 51) {
              int opGlobalPos = (opToken.position + pId * 13) % 52;
              int dist = opGlobalPos - myGlobalPos;
              if (dist < 0) dist += 52;
              
              if (dist > 0 && dist <= 6) {
                // If we are losing, and we can capture someone (especially the leader),
                // give a very high chance to get the exact roll!
                double captureChance = pId == leaderId ? 0.40 : 0.25;
                if (_random.nextDouble() < captureChance) {
                  return dist;
                }
              }
            }
          }
        }
      }
    } else if (isWinning) {
      // If winning, reduce the chance of getting a 6 slightly when stuck
      if (activeTokens == 0 && tokensInHome > 0) {
        if (_random.nextDouble() < 0.20) { // 20% instead of 28%
          return 6;
        }
      }
    } else {
      // NORMAL LOGIC (for players in the middle)
      if (activeTokens == 0 && tokensInHome > 0) {
        if (_random.nextDouble() < 0.28) { 
          return 6;
        }
      }

      if (tokensInHome > 0) {
        if (_random.nextDouble() < 0.20) { 
          return 6;
        }
      }
    }

    // --- Finish Line Assist ---
    // If a player has a token in the home stretch, give a small chance to roll exactly what is needed
    for (var token in myTokens) {
      if (token.position >= 51 && token.position < 56) {
        int needed = 56 - token.position;
        // Nerf finish line assist if winning
        double assistChance = isWinning ? 0.10 : 0.15;
        if (isLosing) assistChance = 0.25;
        
        if (_random.nextDouble() < assistChance) {
          return needed;
        }
      }
    }

    // Default completely random roll
    return _random.nextInt(6) + 1;
  }

  static int _applyKillRig(int playerId, int diceValue, Map<int, List<LudoToken>> playerTokens) {
    bool wouldKill = false;
    List<LudoToken> myTokens = playerTokens[playerId] ?? [];
    
    for (var token in myTokens) {
      if (token.isFinished) continue;
      
      int targetPos = token.position;
      if (token.isHome) {
        if (diceValue == 6) {
          targetPos = 0; // leaves home
        } else {
          continue; // can't move this token
        }
      } else {
        targetPos += diceValue;
      }
      
      if (targetPos > 56) continue;
      
      Offset? movedCoord = GameState.getCoordinate(playerId, targetPos);
      if (movedCoord == null || GameState.safeSpots.contains(movedCoord)) continue;
      
      // Check if this coordinate currently houses exactly 1 opponent token
      for (var entry in playerTokens.entries) {
        if (entry.key == playerId) continue;
        
        List<LudoToken> opOnCell = [];
        for (var op in entry.value) {
          if (!op.isHome && !op.isFinished) {
            if (GameState.getCoordinate(op.playerId, op.position) == movedCoord) {
              opOnCell.add(op);
            }
          }
        }
        
        // Exact capture logic (not a safe zone, not a doubled-up blockade)
        if (opOnCell.length == 1) {
          wouldKill = true;
          break;
        }
      }
      if (wouldKill) break;
    }

    if (wouldKill) {
      // 38% death, 42% +1/-1 or +2/-2, 20% random number
      double rand = _random.nextDouble();
      
      if (rand < 0.38) {
        // 38% chance to Kill: return the intended roll
        return diceValue;
      } else if (rand < 0.80) {
        // 42% chance for +1, -1, +2, or -2 on the dice roll
        List<int> mods = [1, -1, 2, -2];
        int mod = mods[_random.nextInt(mods.length)];
        int newRoll = diceValue + mod;
        
        // Clamp it to valid dice bounds
        if (newRoll < 1) newRoll = 1;
        if (newRoll > 6) newRoll = 6;
        return newRoll;
      } else {
        // 20% chance for random number 1-6
        return _random.nextInt(6) + 1;
      }
    }
    
    return diceValue; // No kill intended, return base roll
  }
}
