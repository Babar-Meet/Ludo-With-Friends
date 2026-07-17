import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/player.dart';
import '../models/game_state.dart';
import 'premium_token_widget.dart';
import 'hopping_token_widget.dart';

class LudoBoardWidget extends StatelessWidget {
  final List<Player> activePlayers;
  final Map<int, List<LudoToken>> playerTokens;
  final Function(LudoToken)? onTokenTap;
  final Set<int> movableTokenIds;
  final int currentTurnPlayerId;

  const LudoBoardWidget({
    super.key, 
    required this.activePlayers,
    required this.playerTokens,
    this.onTokenTap,
    this.movableTokenIds = const {},
    this.currentTurnPlayerId = -1,
  });

  @override
  Widget build(BuildContext context) {
    Map<int, Color> baseColors = {
      0: Colors.blue,
      1: Colors.red,
      2: Colors.green,
      3: Colors.yellow,
    };
    for (var p in activePlayers) {
      baseColors[p.id] = p.color;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: LudoBoardPainter(baseColors: baseColors),
            child: _buildTokensOverlay(constraints.maxWidth, baseColors),
          );
        } catch (e, stack) {
          debugPrint('ERROR inside LudoBoardWidget: $e\n$stack');
          return Container(color: Colors.pink, child: Text('Board Error: $e'));
        }
      },
    );
  }

  Widget _buildTokensOverlay(double size, Map<int, Color> baseColors) {
    double cellSize = size / 15;
    List<Widget> children = [];
    
    // Calculate layout for tokens sharing a cell
    Map<Offset, List<LudoToken>> cellOccupancy = {};
    for (var pTokens in playerTokens.values) {
      for (var token in pTokens) {
        if (!token.isFinished) {
          Offset? coord = GameState.getCoordinate(token.playerId, token.position);
          if (coord != null) {
            cellOccupancy.putIfAbsent(coord, () => []).add(token);
          }
        }
      }
    }
    
    // Add active tokens on the board
    for (var entry in cellOccupancy.entries) {
      Offset coord = entry.key;
      List<LudoToken> cellTokens = entry.value;
      
      double cellCenterX = coord.dx * cellSize + cellSize / 2;
      double cellCenterY = coord.dy * cellSize + cellSize / 2;
      
      for (int i = 0; i < cellTokens.length; i++) {
        LudoToken token = cellTokens[i];
        Player? player = activePlayers.where((p) => p.id == token.playerId).firstOrNull;
        if (player == null) continue;
        
        // Offset slightly if multiple tokens are on the same cell
        double offsetX = 0;
        double offsetY = 0;
        if (cellTokens.length > 1) {
          double radius = cellSize * 0.25;
          double angle = (2 * math.pi * i) / cellTokens.length;
          offsetX = radius * math.cos(angle);
          offsetY = radius * math.sin(angle);
        }
        
        bool isMovable = token.playerId == currentTurnPlayerId && movableTokenIds.contains(token.id);

        children.add(
          HoppingTokenWidget(
            key: ValueKey('${token.playerId}_${token.id}'),
            duration: const Duration(milliseconds: 150),
            left: cellCenterX + offsetX - cellSize * 0.8,
            top: cellCenterY + offsetY - cellSize * 1.5,
            child: IgnorePointer(
              ignoring: !isMovable,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTokenTap?.call(token),
                child: _MovableTokenWrapper(
                  isMovable: isMovable,
                  child: Padding(
                    padding: EdgeInsets.all(isMovable ? 6.0 : 0),
                    child: PremiumTokenWidget(
                      color: baseColors[token.playerId]!,
                      size: cellSize * 1.6,
                      shapeType: player.tokenIndex - 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    // Add tokens in home bases
    children.addAll(_buildHomeTokens(0, 0, 9, cellSize, baseColors[0]!)); // BL
    children.addAll(_buildHomeTokens(1, 0, 0, cellSize, baseColors[1]!)); // TL
    children.addAll(_buildHomeTokens(2, 9, 0, cellSize, baseColors[2]!)); // TR
    children.addAll(_buildHomeTokens(3, 9, 9, cellSize, baseColors[3]!)); // BR
    
    return SizedBox.expand(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
  
  List<Widget> _buildHomeTokens(int id, int startCol, int startRow, double cellSize, Color baseColor) {
    Player? player = activePlayers.where((p) => p.id == id).firstOrNull;
    if (player == null) return [];
    
    List<LudoToken> homeTokens = playerTokens[id]?.where((t) => t.isHome).toList() ?? [];
    if (homeTokens.isEmpty) return [];
    
    double cx = (startCol + 3) * cellSize;
    double cy = (startRow + 3) * cellSize;
    double offset = 1.0 * cellSize; // distance from center of home base
    
    List<Offset> positions = [
      Offset(cx - offset, cy - offset),
      Offset(cx + offset, cy - offset),
      Offset(cx - offset, cy + offset),
      Offset(cx + offset, cy + offset),
    ];
    
    List<Widget> widgets = [];
    for (int i = 0; i < homeTokens.length; i++) {
      LudoToken token = homeTokens[i];
      if (token.id >= positions.length) continue;
      Offset pos = positions[token.id];
      bool isMovable = token.playerId == currentTurnPlayerId && movableTokenIds.contains(token.id);
      
      widgets.add(
        HoppingTokenWidget(
          key: ValueKey('${token.playerId}_${token.id}'),
          duration: const Duration(milliseconds: 150),
          left: pos.dx - cellSize * 0.8,
          top: pos.dy - cellSize * 1.5,
          child: IgnorePointer(
            ignoring: !isMovable,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTokenTap?.call(token),
              child: _MovableTokenWrapper(
                isMovable: isMovable,
                child: Padding(
                  padding: EdgeInsets.all(isMovable ? 6.0 : 0),
                  child: PremiumTokenWidget(
                    color: player.color,
                    size: cellSize * 1.6,
                    shapeType: player.tokenIndex - 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class LudoBoardPainter extends CustomPainter {
  final Map<int, Color> baseColors;
  LudoBoardPainter({required this.baseColors});

  @override
  void paint(Canvas canvas, Size size) {
    double cs = size.width / 15; // cell size
    
    Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // 1. Draw colored paths (home stretches)
    _drawColoredPath(canvas, cs, 7, 9, 1, 5, baseColors[0]!); // BL (Blue) -> Bottom arm
    _drawColoredPath(canvas, cs, 1, 7, 5, 1, baseColors[1]!); // TL (Red) -> Left arm
    _drawColoredPath(canvas, cs, 7, 1, 1, 5, baseColors[2]!); // TR (Green) -> Top arm
    _drawColoredPath(canvas, cs, 9, 7, 5, 1, baseColors[3]!); // BR (Yellow) -> Right arm

    // 2. Draw Start Cells (colored with player base color exactly like path cells)
    _drawColoredPath(canvas, cs, 6, 13, 1, 1, baseColors[0]!); // Blue start
    _drawColoredPath(canvas, cs, 1, 6, 1, 1, baseColors[1]!); // Red start
    _drawColoredPath(canvas, cs, 8, 1, 1, 1, baseColors[2]!); // Green start
    _drawColoredPath(canvas, cs, 13, 8, 1, 1, baseColors[3]!); // Yellow start
    
    // 3. Draw Center triangles
    _drawCenter(canvas, cs, size);
    
    // 4. Draw Grid Lines for paths
    Paint gridPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    // Vertical grid lines in top, bottom arms
    for(int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset((6 + i) * cs, 0), Offset((6 + i) * cs, 6 * cs), gridPaint);
      canvas.drawLine(Offset((6 + i) * cs, 9 * cs), Offset((6 + i) * cs, 15 * cs), gridPaint);
    }
    for(int i = 0; i <= 6; i++) {
      canvas.drawLine(Offset(6 * cs, i * cs), Offset(9 * cs, i * cs), gridPaint);
      canvas.drawLine(Offset(6 * cs, (9 + i) * cs), Offset(9 * cs, (9 + i) * cs), gridPaint);
    }
    
    // Horizontal grid lines in left, right arms
    for(int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, (6 + i) * cs), Offset(6 * cs, (6 + i) * cs), gridPaint);
      canvas.drawLine(Offset(9 * cs, (6 + i) * cs), Offset(15 * cs, (6 + i) * cs), gridPaint);
    }
    for(int i = 0; i <= 6; i++) {
      canvas.drawLine(Offset(i * cs, 6 * cs), Offset(i * cs, 9 * cs), gridPaint);
      canvas.drawLine(Offset((9 + i) * cs, 6 * cs), Offset((9 + i) * cs, 9 * cs), gridPaint);
    }
    
    // 5. Draw Safe Stars (excluding start cells to keep them plain for arrows)
    _drawStar(canvas, cs, 8, 12); // Bottom arm star (Blue path)
    _drawStar(canvas, cs, 2, 8);  // Left arm star (Red path)
    _drawStar(canvas, cs, 6, 2);  // Top arm star (Green path)
    _drawStar(canvas, cs, 12, 6); // Right arm star (Yellow path)

    // 6. Draw 4 Homes (6x6 squares)
    _drawHome(canvas, cs, 0, 9, baseColors[0]!); // BL
    _drawHome(canvas, cs, 0, 0, baseColors[1]!); // TL
    _drawHome(canvas, cs, 9, 0, baseColors[2]!); // TR
    _drawHome(canvas, cs, 9, 9, baseColors[3]!); // BR

    // 7. Draw Openings for Home bases (erases border segment)
    try {
      _drawOpening(canvas, cs, 5, 13, baseColors[0]!, 'right');  // BL -> start at (6,13)
      _drawOpening(canvas, cs, 1, 5, baseColors[1]!, 'bottom'); // TL -> start at (1,6)
      _drawOpening(canvas, cs, 9, 1, baseColors[2]!, 'left');   // TR -> start at (8,1)
      _drawOpening(canvas, cs, 13, 9, baseColors[3]!, 'top');   // BR -> start at (13,8)
    } catch (e) {
      debugPrint('Error in _drawOpening: $e');
    }
  }

  void _drawColoredPath(Canvas canvas, double cs, int c, int r, int w, int h, Color color) {
    Rect rect = Rect.fromLTWH(c * cs, r * cs, w * cs, h * cs);
    // Draw solid color path
    Paint paint = Paint()..color = color;
    canvas.drawRect(rect, paint);
  }

  void _drawHome(Canvas canvas, double cs, int c, int r, Color color) {
    Rect homeRect = Rect.fromLTWH(c * cs, r * cs, 6 * cs, 6 * cs);
    
    // Outer shadow
    canvas.drawRect(
      homeRect.translate(2, 2),
      Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Premium base with solid color
    Paint paint = Paint()..color = color;
    canvas.drawRect(homeRect, paint);
    
    // Glossy border
    Paint borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(homeRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(homeRect, borderPaint);
    
    // Draw white inner square with inner shadow effect
    Rect innerRect = Rect.fromLTWH((c + 1) * cs, (r + 1) * cs, 4 * cs, 4 * cs);
    Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(8)), whitePaint);
    
    // Inner shadow for white square
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw 4 token slots (recessed look)
    _drawHomeTokenSlot(canvas, cs, c + 1.5, r + 1.5, color);
    _drawHomeTokenSlot(canvas, cs, c + 3.5, r + 1.5, color);
    _drawHomeTokenSlot(canvas, cs, c + 1.5, r + 3.5, color);
    _drawHomeTokenSlot(canvas, cs, c + 3.5, r + 3.5, color);
  }

  void _drawHomeTokenSlot(Canvas canvas, double cs, double c, double r, Color color) {
    Offset center = Offset(c * cs + cs / 2, r * cs + cs / 2);
    double radius = cs * 0.8;
    
    // Recessed shadow
    canvas.drawCircle(
      center.translate(1, 1),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.inner, 3),
    );
    
    // Base circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color,
    );
    
    // Glossy rim
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawCenter(Canvas canvas, double cs, Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;
    
    Path topP = Path()..moveTo(cx - 1.5*cs, cy - 1.5*cs)..lineTo(cx + 1.5*cs, cy - 1.5*cs)..lineTo(cx, cy)..close();
    canvas.drawPath(topP, Paint()..color = baseColors[2]!);
    
    Path rightP = Path()..moveTo(cx + 1.5*cs, cy - 1.5*cs)..lineTo(cx + 1.5*cs, cy + 1.5*cs)..lineTo(cx, cy)..close();
    canvas.drawPath(rightP, Paint()..color = baseColors[3]!);
    
    Path bottomP = Path()..moveTo(cx - 1.5*cs, cy + 1.5*cs)..lineTo(cx + 1.5*cs, cy + 1.5*cs)..lineTo(cx, cy)..close();
    canvas.drawPath(bottomP, Paint()..color = baseColors[0]!);
    
    Path leftP = Path()..moveTo(cx - 1.5*cs, cy - 1.5*cs)..lineTo(cx - 1.5*cs, cy + 1.5*cs)..lineTo(cx, cy)..close();
    canvas.drawPath(leftP, Paint()..color = baseColors[1]!);
  }


  void _drawStar(Canvas canvas, double cs, int c, int r) {
    double cx = c * cs + cs / 2;
    double cy = r * cs + cs / 2;
    double outerR = cs * 0.35;
    double innerR = cs * 0.18;
    
    Path path = Path();
    for (int i = 0; i < 10; i++) {
      double angle = -math.pi / 2 + i * math.pi / 5;
      double radius = i.isEven ? outerR : innerR;
      double x = cx + radius * math.cos(angle);
      double y = cy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    
    // Gold gradient star
    Paint paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: outerR));
    
    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()..color = Colors.black.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1);
  }



  void _drawOpening(Canvas canvas, double cs, int c, int r, Color color, String side) {
    // We'll draw a glowing opening effect
    double w = (side == 'top' || side == 'bottom') ? cs : cs * 0.4;
    double h = (side == 'left' || side == 'right') ? cs : cs * 0.4;
    
    double dx = c * cs;
    double dy = r * cs;
    
    if (side == 'right') dx += cs * 0.6;
    if (side == 'bottom') dy += cs * 0.6;
    
    Rect rect = Rect.fromLTWH(dx, dy, w, h);
    Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.0)],
        begin: side == 'left' ? Alignment.centerRight : side == 'right' ? Alignment.centerLeft : side == 'top' ? Alignment.bottomCenter : Alignment.topCenter,
        end: side == 'left' ? Alignment.centerLeft : side == 'right' ? Alignment.centerRight : side == 'top' ? Alignment.topCenter : Alignment.bottomCenter,
      ).createShader(rect);
      
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MovableTokenWrapper extends StatefulWidget {
  final bool isMovable;
  final Widget child;

  const _MovableTokenWrapper({required this.isMovable, required this.child});

  @override
  State<_MovableTokenWrapper> createState() => _MovableTokenWrapperState();
}

class _MovableTokenWrapperState extends State<_MovableTokenWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isMovable) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_MovableTokenWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMovable && !oldWidget.isMovable) {
      _controller.repeat(reverse: true);
    } else if (!widget.isMovable && oldWidget.isMovable) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMovable) return widget.child;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 15 * (_controller.value),
                          spreadRadius: 2 * (_controller.value),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
