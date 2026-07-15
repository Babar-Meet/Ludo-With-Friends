import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import '../models/game_state.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/premium_token_widget.dart';
import '../widgets/dice_widget.dart';
import '../utils/bot_ai.dart';
import '../utils/smart_dice.dart';
import '../utils/audio_manager.dart';
import '../widgets/player_settings_dialog.dart';


class GameScreen extends StatefulWidget {
  final List<Player> activePlayers;
  final bool isDevMode;
  final bool autoStartBots;

  const GameScreen({
    super.key, 
    required this.activePlayers,
    this.isDevMode = false,
    this.autoStartBots = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  int currentTurnPlayerId = 0;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Ludo State
  Map<int, List<LudoToken>> playerTokens = {};
  bool isDiceRolling = false;
  bool isAnimating = false; // Lock interactions during token animations
  bool isArrangeMode = false; // Dev Test Mode feature
  Set<int> movableTokenIds = {}; // IDs of tokens that can legally move this turn
  int diceValue = 1;
  int consecutiveSixes = 0;
  bool hasRolledDice = false;
  Map<int, bool> playerAutoRoll = {};
  Map<int, bool> playerAutoMove = {};
  Map<int, bool> playerBotMode = {};

  // Audio Preferences
  Map<int, String> playerDiceSound = {};
  Map<int, String> playerMoveSound = {};
  Map<int, String> playerCaptureSound = {};
  Map<int, String> playerWinSound = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize tokens and settings
    for (var p in widget.activePlayers) {
      playerTokens[p.id] = List.generate(4, (i) => LudoToken(id: i, playerId: p.id));
      
      bool isBot = widget.autoStartBots && p.id != widget.activePlayers.first.id;
      playerAutoRoll[p.id] = isBot;
      playerAutoMove[p.id] = isBot;
      playerBotMode[p.id] = isBot;
      
      // Default sounds
      playerDiceSound[p.id] = 'dice_glass.wav';
      playerMoveSound[p.id] = 'move_default.wav';
      playerCaptureSound[p.id] = 'capture_zap.wav';
      playerWinSound[p.id] = 'win_retro.wav';
    }

    if (widget.activePlayers.isNotEmpty) {
      currentTurnPlayerId = widget.activePlayers.first.id;
    }
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Initial roll check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoRoll();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (isDiceRolling || hasRolledDice || isAnimating) return;
    
    if (widget.isDevMode && !playerBotMode[currentTurnPlayerId]!) {
      _showManualDiceDialog().then((manualDice) {
        if (manualDice != null) {
          setState(() {
            diceValue = manualDice;
            hasRolledDice = true;
            _checkValidMoves();
          });
        }
      });
      return;
    }
    
    AudioManager.playDice(filename: playerDiceSound[currentTurnPlayerId]);
    
    setState(() {
      isDiceRolling = true;
      movableTokenIds.clear();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        isDiceRolling = false;
        bool isBot = playerBotMode[currentTurnPlayerId] == true;
        try {
          diceValue = SmartDice.roll(currentTurnPlayerId, playerTokens, isBot: isBot);
        } catch (e) {
          diceValue = 1; // Fallback
        }
        hasRolledDice = true;
        
        if (diceValue == 6) {
          consecutiveSixes++;
          if (consecutiveSixes >= 3) {
            consecutiveSixes = 0;
            _showToast("Three 6s! Turn Lost 😱");
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) _nextTurn();
            });
            return;
          }
        } else {
          consecutiveSixes = 0;
        }
        
        _checkValidMoves();
      });
    });
  }
  
  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 150, left: 50, right: 50),
        duration: const Duration(milliseconds: 1200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
      ),
    );
  }

  void _checkValidMoves() {
    List<LudoToken> tokens = playerTokens[currentTurnPlayerId] ?? [];
    bool hasValidMove = false;
    movableTokenIds.clear();

    for (var token in tokens) {
      if (token.isHome) {
        if (diceValue == 6) {
          hasValidMove = true;
          movableTokenIds.add(token.id);
        }
      } else if (!token.isFinished) {
        if (token.position + diceValue <= 56) {
          hasValidMove = true;
          movableTokenIds.add(token.id);
        }
      }
    }

    if (!hasValidMove) {
      // Pass turn faster
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _nextTurn();
      });
    } else {
      // Check if we should auto-move or bot-move
      bool isAutoMove = playerAutoMove[currentTurnPlayerId] == true || playerBotMode[currentTurnPlayerId] == true;
      if (isAutoMove) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          // Use BotAI to find the best move
          LudoToken? bestMove;
          try {
            bestMove = BotAI.getBestMove(currentTurnPlayerId, diceValue, playerTokens);
          } catch(e) {
             // Fallback: just pick the first valid move if AI crashes
             if (movableTokenIds.isNotEmpty) {
               bestMove = tokens.firstWhere((t) => t.id == movableTokenIds.first);
             }
          }
          
          if (bestMove != null) {
            _handleTokenTap(bestMove);
          } else {
            _nextTurn();
          }
        });
      } else if (movableTokenIds.length == 1) {
        // Auto-move if there is only 1 valid move for a human player
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          LudoToken onlyMove = tokens.firstWhere((t) => t.id == movableTokenIds.first);
          _handleTokenTap(onlyMove);
        });
      }
    }
  }

  void _handleTokenTap(LudoToken token) async {
    if (widget.isDevMode && isArrangeMode) {
      int? newPos = await _showPositionDialog(token.position);
      if (newPos != null) {
        setState(() {
          token.position = newPos.clamp(-1, 56);
        });
      }
      return;
    }
    
    if (token.playerId != currentTurnPlayerId) return;
    if (!hasRolledDice || isDiceRolling || isAnimating) return;
    if (!movableTokenIds.contains(token.id)) return;

    if (token.isHome) {
      if (diceValue == 6) {
        setState(() {
          token.position = 0;
          hasRolledDice = false;
          movableTokenIds.clear();
          _checkAutoRoll(); // Extra turn for rolling a 6
        });
      }
    } else if (!token.isFinished) {
      if (token.position + diceValue <= 56) {
        setState(() {
          hasRolledDice = false;
          isAnimating = true;
          movableTokenIds.clear();
        });
        
        _animateTokenForward(token, diceValue, () {
          bool extraTurn = diceValue == 6;

          if (token.position == 56) {
            extraTurn = true; // Reach home gets extra turn
            AudioManager.playWin(filename: playerWinSound[token.playerId]);
            setState(() { isAnimating = false; });
            
            if (_checkWinCondition(token.playerId)) {
              return; // Stop turn logic if game is over
            }

            if (!extraTurn) {
              _nextTurn();
            } else {
              _checkAutoRoll();
            }
          } else {
            // Check for capture
            LudoToken? capturedOpponent = _checkCapture(token);
            if (capturedOpponent != null) {
              extraTurn = true;
              AudioManager.playCapture(filename: playerCaptureSound[currentTurnPlayerId]);
              
              setState(() {
                capturedOpponent.position = -1;
              });
              Future.delayed(const Duration(milliseconds: 800), () { // wait for flying animation
                if (mounted) {
                  setState(() { isAnimating = false; });
                  _checkAutoRoll();
                }
              });
            } else {
              setState(() { isAnimating = false; });
              if (!extraTurn) {
                _nextTurn();
              } else {
                _checkAutoRoll();
              }
            }
          }
        });
      }
    }
  }

  void _animateTokenForward(LudoToken token, int steps, VoidCallback onComplete) {
    if (steps <= 0 || token.position >= 56) {
      onComplete();
      return;
    }
    
    AudioManager.playMove(filename: playerMoveSound[token.playerId]);
    
    setState(() {
      token.position += 1;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _animateTokenForward(token, steps - 1, onComplete);
    });
  }

  void _animateTokenReverse(LudoToken token, int steps, VoidCallback onComplete) {
    if (steps <= 0 || token.position <= -1) {
      onComplete();
      return;
    }
    
    AudioManager.playMove(filename: playerMoveSound[token.playerId]); // Ticking sound backwards too!
    
    setState(() {
      token.position -= 1;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _animateTokenReverse(token, steps - 1, onComplete);
    });
  }

  LudoToken? _checkCapture(LudoToken movedToken) {
    Offset? movedCoord = GameState.getCoordinate(movedToken.playerId, movedToken.position);
    if (movedCoord == null) return null;
    
    if (GameState.safeSpots.contains(movedCoord)) return null;

    for (var entry in playerTokens.entries) {
      if (entry.key == movedToken.playerId) continue;
      
      List<LudoToken> opponentTokensOnCell = [];
      for (var opToken in entry.value) {
        if (!opToken.isHome && !opToken.isFinished) {
          Offset? opCoord = GameState.getCoordinate(opToken.playerId, opToken.position);
          if (opCoord == movedCoord) {
            opponentTokensOnCell.add(opToken);
          }
        }
      }

      // Capture only if exactly 1 opponent token is on the cell (not safe)
      if (opponentTokensOnCell.length == 1) {
        return opponentTokensOnCell.first;
      }
    }
    return null;
  }

  bool _checkWinCondition(int playerId) {
    List<LudoToken> pTokens = playerTokens[playerId] ?? [];
    bool hasWon = pTokens.every((t) => t.isFinished);
    
    if (hasWon) {
      Player p = widget.activePlayers.firstWhere((player) => player.id == playerId);
      _showWinnerDialog(p);
      return true;
    }
    return false;
  }

  void _showWinnerDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
              const SizedBox(width: 10),
              Text('Winner!', style: TextStyle(color: winner.color, fontWeight: FontWeight.bold, fontSize: 28)),
            ],
          ),
          content: Text(
            '${winner.name} has moved all their tokens to the center and won the game!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: winner.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Playing'),
            )
          ],
        );
      }
    );
  }

  void _nextTurn() {
    setState(() {
      consecutiveSixes = 0;
      hasRolledDice = false;
      movableTokenIds.clear();
      int currentIndex = widget.activePlayers.indexWhere((p) => p.id == currentTurnPlayerId);
      if (currentIndex != -1) {
        int nextIndex = (currentIndex + 1) % widget.activePlayers.length;
        currentTurnPlayerId = widget.activePlayers[nextIndex].id;
      }
      _checkAutoRoll();
    });
  }

  void _checkAutoRoll() {
    bool isAutoRoll = playerAutoRoll[currentTurnPlayerId] == true || playerBotMode[currentTurnPlayerId] == true;
    if (isAutoRoll && !hasRolledDice && !isDiceRolling && !isAnimating) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _rollDice();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Player? p0 = widget.activePlayers.where((p) => p.id == 0).firstOrNull; // BL
    Player? p1 = widget.activePlayers.where((p) => p.id == 1).firstOrNull; // TL
    Player? p2 = widget.activePlayers.where((p) => p.id == 2).firstOrNull; // TR
    Player? p3 = widget.activePlayers.where((p) => p.id == 3).firstOrNull; // BR

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFF003366));
            }
          ),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row (Player 1 and Player 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlayerCorner(p1, left: true),
                      _buildPlayerCorner(p2, left: false),
                    ],
                  ),
                ),
                
                // The Board
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double boardSize = constraints.maxWidth < constraints.maxHeight 
                            ? constraints.maxWidth 
                            : constraints.maxHeight;
                        boardSize -= 16; 
                        
                        return Container(
                          width: boardSize,
                          height: boardSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: LudoBoardWidget(
                            activePlayers: widget.activePlayers,
                            playerTokens: playerTokens,
                            onTokenTap: _handleTokenTap,
                            movableTokenIds: movableTokenIds,
                            currentTurnPlayerId: currentTurnPlayerId,
                          ),
                        );
                      }
                    ),
                  ),
                ),
                
                // Bottom Row (Player 0 and Player 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlayerCorner(p0, left: true),
                      _buildPlayerCorner(p3, left: false),
                    ],
                  ),
                ),
                
                // Padding for bottom safely
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          if (widget.isDevMode)
            Positioned(
              top: 10,
              left: 10,
              child: FloatingActionButton.extended(
                heroTag: 'arrange_mode_btn',
                backgroundColor: isArrangeMode ? Colors.red : Colors.green,
                onPressed: () {
                  setState(() {
                    isArrangeMode = !isArrangeMode;
                  });
                },
                label: Text(
                  isArrangeMode ? 'Arrange: ON' : 'Arrange: OFF',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                icon: Icon(isArrangeMode ? Icons.edit : Icons.edit_off, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<int?> _showManualDiceDialog() {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dev Mode: Enter Dice (1-6)'),
          content: Wrap(
            spacing: 10,
            children: List.generate(6, (i) => 
              ElevatedButton(
                onPressed: () => Navigator.pop(context, i + 1),
                child: Text('${i + 1}'),
              )
            ),
          ),
        );
      }
    );
  }

  Future<int?> _showPositionDialog(int currentPos) {
    TextEditingController ctrl = TextEditingController(text: currentPos.toString());
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dev Mode: Set Position'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '-1 (Home), 0 (Start), 56 (Win)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
              child: const Text('SET'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPlayerCorner(Player? player, {required bool left}) {
    if (player == null) {
      return const SizedBox(width: 140, height: 80); // Empty placeholder
    }
    
    bool isTurn = player.id == currentTurnPlayerId;

    // Unified Slim Box (Avatar + Dice)
    Widget unifiedBox = Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: isTurn ? Border.all(color: Colors.amber, width: 3) : Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: isTurn ? [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
        ] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(1, 1))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7), // slightly less than container to fit inside border
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left side: Player color gradient + Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [player.color, player.color.withValues(alpha: 0.2)],
                  begin: left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                )
              ),
              child: Center(
                child: SizedBox(
                  width: 35,
                  height: 35,
                  child: PremiumTokenWidget(
                    color: Colors.white, // High contrast against the colored background
                    size: 35,
                    shapeType: player.tokenIndex - 1,
                  ),
                ),
              ),
            ),
            // Right side: Dice section (pink gradient)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade50, Colors.pink.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              ),
              child: Center(
                child: isTurn 
                  ? DiceWidget(
                      value: diceValue,
                      isRolling: isDiceRolling,
                      onRoll: _rollDice,
                    )
                  : Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    // Bouncing Arrow pointing to the box
    Widget animatedArrow = isTurn ? AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        // _glowAnimation goes from 0.2 to 0.8. We map this to a bounce translation of 2 to 8 pixels.
        double offset = _glowAnimation.value * 10;
        return Transform.translate(
          offset: Offset(left ? -offset : offset, 0),
          child: Icon(
            left ? Icons.arrow_left : Icons.arrow_right,
            color: Colors.amber,
            size: 40,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
          ),
        );
      }
    ) : const SizedBox(width: 40);

    // Name label
    Widget nameBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        player.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Settings Button to open PlayerSettingsDialog
    Widget settingsButton = IconButton(
      icon: const Icon(Icons.settings, color: Colors.white70, size: 24),
      onPressed: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => PlayerSettingsDialog(
            player: player,
            initialAutoRoll: playerAutoRoll[player.id] ?? false,
            initialAutoMove: playerAutoMove[player.id] ?? false,
            initialBotMode: playerBotMode[player.id] ?? false,
            initialDiceSound: playerDiceSound[player.id] ?? 'dice_glass.wav',
            initialMoveSound: playerMoveSound[player.id] ?? 'move_default.wav',
            initialCaptureSound: playerCaptureSound[player.id] ?? 'capture_zap.wav',
            initialWinSound: playerWinSound[player.id] ?? 'win_retro.wav',
          ),
        );
        
        if (result != null && result is Map) {
          setState(() {
            playerAutoRoll[player.id] = result['autoRoll'];
            playerAutoMove[player.id] = result['autoMove'];
            playerBotMode[player.id] = result['botMode'];
            
            playerDiceSound[player.id] = result['diceSound'];
            playerMoveSound[player.id] = result['moveSound'];
            playerCaptureSound[player.id] = result['captureSound'];
            playerWinSound[player.id] = result['winSound'];
            
            _checkAutoRoll();
          });
        }
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );

    Widget topRow = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        nameBox,
        const SizedBox(height: 4),
        settingsButton,
      ],
    );

    Widget contentRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: left 
          ? [unifiedBox, animatedArrow] 
          : [animatedArrow, unifiedBox],
    );

    bool isTopPlayer = player.id == 1 || player.id == 2;

    Widget finalCorner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        topRow,
        const SizedBox(height: 4),
        contentRow,
      ],
    );

    if (isTopPlayer) {
      return RotatedBox(
        quarterTurns: 2,
        child: finalCorner,
      );
    }
    return finalCorner;
  }
}
