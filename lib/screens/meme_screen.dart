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
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() => _showVideo = true);
          _fadeController.forward();
          _controller.play();
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✕ Close',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
              FadeTransition(
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
                          width: squareSize,
                          height: squareSize,
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
                            width: squareSize,
                            height: squareSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white12,
                            ),
                            child: const Center(
                                child: CircularProgressIndicator(color: Colors.white)),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
