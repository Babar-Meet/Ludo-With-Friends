import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludo_with_friends/screens/game_screen.dart';
import 'package:ludo_with_friends/models/player.dart';

void main() {
  testWidgets('Test GameScreen rendering', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR: ${details.exceptionAsString()}');
      print(details.stack.toString());
    };

    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        activePlayers: [
          Player(id: 0, name: 'Player 1', color: Colors.blue, tokenIndex: 1),
          Player(id: 2, name: 'Player 2', color: Colors.red, tokenIndex: 2),
        ],
      ),
    ));
    
    await tester.pump(const Duration(seconds: 1));
    print('Render completed without crashing.');
  });
}
