import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/player.dart';
import 'premium_token_widget.dart';

class GameSetupDialog extends StatefulWidget {
  const GameSetupDialog({super.key});

  @override
  State<GameSetupDialog> createState() => _GameSetupDialogState();
}

class _GameSetupDialogState extends State<GameSetupDialog> {
  int _playerCount = 2;
  
  final List<Color> _playerColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
  ];
  
  // Stores the selected token index (1 to 6) for each player. Default to token 4 (classic map pin)
  final List<int> _playerTokens = [4, 4, 4, 4];

  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _controllers.add(TextEditingController(text: 'Player_${i + 1}'));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showColorPicker(BuildContext context, int playerIndex) {
    // Quick selection colors requested by the user
    final List<Color> quickColors = [
      Colors.red, Colors.green, Colors.blue, Colors.yellow,
      Colors.pink, Colors.white, Colors.black,
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF003366),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: const Text(
            'SELECT TOKEN COLOR',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: [
                  ...quickColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _playerColors[playerIndex] = color;
                        });
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Custom Color Button (Rainbow circle)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showFullColorPicker(context, playerIndex);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                        gradient: const SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullColorPicker(BuildContext context, int playerIndex) {
    Color pickerColor = _playerColors[playerIndex];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF003366),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: const Text(
            'PICK ANY COLOR',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('SELECT', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _playerColors[playerIndex] = pickerColor;
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTokenPicker(BuildContext context, int playerIndex) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF003366),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: const Text(
            'SELECT TOKEN',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                int tokenNumber = index + 1;
                bool isSelected = _playerTokens[playerIndex] == tokenNumber;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _playerTokens[playerIndex] = tokenNumber;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent, 
                        width: 3
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: Center(
                      child: PremiumTokenWidget(
                        color: _playerColors[playerIndex],
                        size: 40,
                        shapeType: index,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Row(
        children: [
          // Color indicator
          GestureDetector(
            onTap: () => _showColorPicker(context, index),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _playerColors[index],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Token Shape Selector
          GestureDetector(
            onTap: () => _showTokenPicker(context, index),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _playerColors[index], width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: PremiumTokenWidget(
                  color: _playerColors[index],
                  size: 35,
                  shapeType: _playerTokens[index] - 1, // shapeType is index - 1
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Name Input
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _controllers[index],
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF004488), Color(0xFF002244)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'CHOOSE COLOR, TOKEN & NAME',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            
            // Player Rows
            for (int i = 0; i < _playerCount; i++) _buildPlayerRow(i),
            
            const SizedBox(height: 30),
            
            // Player Count Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlayerCountButton(2),
                const SizedBox(width: 15),
                _buildPlayerCountButton(3),
                const SizedBox(width: 15),
                _buildPlayerCountButton(4),
              ],
            ),
            
            const SizedBox(height: 35),
            
            // Play Button
            ElevatedButton(
              onPressed: () {
                List<Player> activePlayers = [];
                for (int i = 0; i < _playerCount; i++) {
                  int boardId = i;
                  if (_playerCount == 2 && i == 1) {
                    boardId = 2; // In 2-player, map 2nd player to top-right
                  }
                  activePlayers.add(Player(
                    id: boardId,
                    name: _controllers[i].text,
                    color: _playerColors[i],
                    tokenIndex: _playerTokens[i],
                  ));
                }
                Navigator.of(context).pop(activePlayers);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.amber, width: 3),
                ),
                elevation: 10,
              ),
              child: const Text(
                'Play',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPlayerCountButton(int count) {
    bool isSelected = _playerCount == count;
    return GestureDetector(
      onTap: () {
        setState(() {
          _playerCount = count;
        });
      },
      child: Container(
        width: 55,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.amber,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          '${count}P',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: isSelected
                ? const [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
