import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MemeScreen extends StatefulWidget {
  const MemeScreen({super.key});

  @override
  State<MemeScreen> createState() => _MemeScreenState();
}

class _MemeScreenState extends State<MemeScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  final _text = 'You have no friends to play with 😢';
  var _visibleChars = 0;
  var _showVideoSpace = false;
  var _showVideo = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _controller = VideoPlayerController.asset('assets/meme/Laughing_Cat_Meme.mp4')
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
      });
    _startTyping();
  }

  void _startTyping() {
    Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (_visibleChars >= _text.length) {
        timer.cancel();
        // Give user time to read the text
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          // 1. Expand the space (slides text up)
          setState(() => _showVideoSpace = true);
          
          // 2. Wait for slide to finish, then fade in and play video
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            setState(() => _showVideo = true);
            _fadeController.forward();
            _controller.play();
          });
        });
        return;
      }
      setState(() => _visibleChars++);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final squareSize = size.width * 0.85;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Text(
                    '✕ Close',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Text(
                _text.substring(0, _visibleChars),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AnimatedSize(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
                child: _showVideoSpace 
                  ? SizedBox(
                      width: squareSize,
                      height: squareSize,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _showVideo && _controller.value.isInitialized
                            ? GestureDetector(
                                onTap: () {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white24, width: 2),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Center(
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                              )
                            : _showVideo
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white12,
                                    ),
                                    child: const Center(
                                        child: CircularProgressIndicator(color: Colors.white)),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
