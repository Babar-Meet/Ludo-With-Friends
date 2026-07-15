import 'package:flutter/material.dart';
import '../widgets/game_setup_dialog.dart';
import '../models/player.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
          ),
          // Dark overlay to make foreground pop and hide mismatched background edges
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the logo in a polished circular container
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                
                // Play with Random (Bots)
                _buildMenuButton(
                  title: 'PLAY WITH RANDOM',
                  color: Colors.blueAccent,
                  context: context,
                  onPressed: () {
                    List<Player> players = [];
                    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow];
                    for (int i = 0; i < 4; i++) {
                      players.add(Player(
                        id: i, 
                        name: i == 0 ? 'You' : 'Bot $i', 
                        color: colors[i], 
                        tokenIndex: 4
                      ));
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                          activePlayers: players, 
                          autoStartBots: true,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Play with Friend (Local Multiplayer Setup)
                _buildMenuButton(
                  title: 'PLAY WITH FRIEND',
                  color: Colors.amber,
                  textColor: Colors.black,
                  context: context,
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => const GameSetupDialog(),
                    );
                    if (result != null && result is List) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            activePlayers: List<Player>.from(result),
                          ),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Dev Test Mode
                _buildMenuButton(
                  title: 'DEV TEST MODE',
                  color: Colors.redAccent,
                  context: context,
                  onPressed: () {
                    List<Player> players = [];
                    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow];
                    for (int i = 0; i < 4; i++) {
                      players.add(Player(
                        id: i, 
                        name: 'Test Player $i', 
                        color: colors[i], 
                        tokenIndex: 4
                      ));
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                          activePlayers: players, 
                          isDevMode: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title, 
    required Color color, 
    Color textColor = Colors.white, 
    required BuildContext context,
    required VoidCallback onPressed
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(280, 60),
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
