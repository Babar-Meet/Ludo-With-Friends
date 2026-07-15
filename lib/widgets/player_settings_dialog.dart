import 'package:flutter/material.dart';
import '../models/player.dart';
import '../utils/audio_manager.dart';

class PlayerSettingsDialog extends StatefulWidget {
  final Player player;
  final bool initialAutoRoll;
  final bool initialAutoMove;
  final bool initialBotMode;
  
  final String initialDiceSound;
  final String initialMoveSound;
  final String initialCaptureSound;
  final String initialWinSound;

  const PlayerSettingsDialog({
    super.key,
    required this.player,
    required this.initialAutoRoll,
    required this.initialAutoMove,
    required this.initialBotMode,
    required this.initialDiceSound,
    required this.initialMoveSound,
    required this.initialCaptureSound,
    required this.initialWinSound,
  });

  @override
  State<PlayerSettingsDialog> createState() => _PlayerSettingsDialogState();
}

class _PlayerSettingsDialogState extends State<PlayerSettingsDialog> {
  late bool autoRoll;
  late bool autoMove;
  late bool botMode;
  
  late String diceSound;
  late String moveSound;
  late String captureSound;
  late String winSound;

  final List<String> diceOptions = ['dice_default.wav', 'dice_wood.wav', 'dice_glass.wav'];
  final List<String> moveOptions = ['move_default.wav', 'move_slide.wav', 'move_thud.wav'];
  final List<String> captureOptions = ['capture_default.wav', 'capture_punch.wav', 'capture_zap.wav'];
  final List<String> winOptions = ['win_default.wav', 'win_chime.wav', 'win_retro.wav'];

  @override
  void initState() {
    super.initState();
    autoRoll = widget.initialAutoRoll;
    autoMove = widget.initialAutoMove;
    botMode = widget.initialBotMode;
    
    diceSound = widget.initialDiceSound;
    moveSound = widget.initialMoveSound;
    captureSound = widget.initialCaptureSound;
    winSound = widget.initialWinSound;
  }

  Widget _buildToggleRow(String title, bool value, Color activeColor, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundRow(String title, String currentValue, List<String> options, ValueChanged<String?> onChanged, VoidCallback onPlay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          DropdownButton<String>(
            value: currentValue,
            dropdownColor: const Color(0xFF002244),
            style: const TextStyle(color: Colors.amber, fontSize: 14),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
            underline: Container(height: 1, color: Colors.amber.withOpacity(0.5)),
            items: options.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val.replaceAll('.wav', '').replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
            onPressed: onPlay,
            tooltip: 'Preview Sound',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF003366),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: widget.player.color, width: 3),
      ),
      title: Row(
        children: [
          Icon(Icons.settings, color: widget.player.color),
          const SizedBox(width: 8),
          Text(
            '${widget.player.name} Settings',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AUTOMATION', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Divider(color: Colors.white24),
            _buildToggleRow('Auto Roll', autoRoll, Colors.blue, (val) {
              setState(() {
                autoRoll = val;
                if (!val) botMode = false;
                else if (autoMove) botMode = true;
              });
            }),
            _buildToggleRow('Auto Move', autoMove, Colors.orange, (val) {
              setState(() {
                autoMove = val;
                if (!val) botMode = false;
                else if (autoRoll) botMode = true;
              });
            }),
            _buildToggleRow('Full Bot Mode', botMode, Colors.purple, (val) {
              setState(() {
                botMode = val;
                if (val) {
                  autoRoll = true;
                  autoMove = true;
                } else {
                  autoRoll = false;
                  autoMove = false;
                }
              });
            }),
            
            const SizedBox(height: 20),
            
            const Text('SOUND EFFECTS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Divider(color: Colors.white24),
            
            _buildSoundRow('Dice Roll', diceSound, diceOptions, (val) {
              if (val != null) setState(() => diceSound = val);
            }, () => AudioManager.playDice(filename: diceSound)),
            
            _buildSoundRow('Token Move', moveSound, moveOptions, (val) {
              if (val != null) setState(() => moveSound = val);
            }, () => AudioManager.playMove(filename: moveSound)),
            
            _buildSoundRow('Capture Enemy', captureSound, captureOptions, (val) {
              if (val != null) setState(() => captureSound = val);
            }, () => AudioManager.playCapture(filename: captureSound)),
            
            _buildSoundRow('Victory', winSound, winOptions, (val) {
              if (val != null) setState(() => winSound = val);
            }, () => AudioManager.playWin(filename: winSound)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel returns null
          child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          onPressed: () {
            Navigator.of(context).pop({
              'autoRoll': autoRoll,
              'autoMove': autoMove,
              'botMode': botMode,
              'diceSound': diceSound,
              'moveSound': moveSound,
              'captureSound': captureSound,
              'winSound': winSound,
            });
          },
          child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
