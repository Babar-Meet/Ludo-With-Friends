import 'package:flutter/material.dart';
import 'dart:math' as math;

class HoppingTokenWidget extends StatefulWidget {
  final double left;
  final double top;
  final Widget child;
  final Duration duration;
  final double cellSize;

  const HoppingTokenWidget({
    super.key,
    required this.left,
    required this.top,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.cellSize = 40.0,
  });

  @override
  State<HoppingTokenWidget> createState() => _HoppingTokenWidgetState();
}

class _HoppingTokenWidgetState extends State<HoppingTokenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _startLeft = 0;
  double _startTop = 0;

  @override
  void initState() {
    super.initState();
    _startLeft = widget.left;
    _startTop = widget.top;
    
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  }

  @override
  void didUpdateWidget(covariant HoppingTokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left != widget.left || oldWidget.top != widget.top) {
      double t = _controller.isAnimating ? _animation.value : 1.0;
      _startLeft = _startLeft + (oldWidget.left - _startLeft) * t;
      _startTop = _startTop + (oldWidget.top - _startTop) * t;
      
      double dx = widget.left - _startLeft;
      double dy = widget.top - _startTop;
      double distance = math.sqrt(dx * dx + dy * dy);
      double distInCells = distance / widget.cellSize;
      
      if (distInCells > 1.5) {
        int millis = (distInCells * 150).round().clamp(400, 2000);
        _controller.duration = Duration(milliseconds: millis);
      } else {
        _controller.duration = widget.duration;
      }
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double t = _animation.value;
        double currentLeft = _startLeft + (widget.left - _startLeft) * t;
        double currentTop = _startTop + (widget.top - _startTop) * t;
        
        double dx = widget.left - _startLeft;
        double dy = widget.top - _startTop;
        double distance = math.sqrt(dx * dx + dy * dy);
        double distInCells = distance / widget.cellSize;
        bool isFlying = distInCells > 1.5;
        
        double sinTPi = math.sin(t * math.pi);
        double hopOffset = isFlying ? sinTPi * 120.0 : sinTPi * 35.0;
        
        double scaleX = 1.0;
        double scaleY = 1.0;
        
        if (_controller.isAnimating && !isFlying) {
          scaleY = 1.0 + sinTPi * 0.25;
          scaleX = 1.0 - sinTPi * 0.15;
        } else if (_controller.isAnimating && isFlying) {
          scaleY = 1.1;
          scaleX = 0.9;
        }

        double angle = 0.0;
        if (_controller.isAnimating) {
          if (isFlying) {
            angle = t * math.pi * 4;
          } else {
            if (dx > 5) angle = math.pi / 8;
            else if (dx < -5) angle = -math.pi / 8;
            else if (dy < -5) angle = math.pi / 12;
            else if (dy > 5) angle = -math.pi / 12;
            angle = angle * sinTPi;
          }
        }
        
        return Positioned(
          left: currentLeft,
          top: currentTop - hopOffset,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..rotateZ(angle)
              ..scale(scaleX, scaleY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
