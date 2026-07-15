import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludo_with_friends/screens/game_screen.dart';
import 'package:ludo_with_friends/models/player.dart';
import 'package:ludo_with_friends/widgets/ludo_board_widget.dart';

void main() {
  testWidgets('GameScreen layout does not collapse and LudoBoardWidget renders', (WidgetTester tester) async {
    // Provide a physical size for the test environment
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    List<Player> activePlayers = [
      Player(id: 0, name: 'Player_1', color: Colors.blue, tokenIndex: 1),
      Player(id: 2, name: 'Player_2', color: Colors.green, tokenIndex: 1),
    ];

    await tester.pumpWidget(MaterialApp(
      home: GameScreen(activePlayers: activePlayers),
    ));

    // Wait for all animations and layouts to settle
    await tester.pumpAndSettle();

    // Verify GameScreen is in the tree
    expect(find.byType(GameScreen), findsOneWidget);

    // Verify LudoBoardWidget is in the tree
    expect(find.byType(LudoBoardWidget), findsOneWidget);
    
    // Verify player corners exist
    expect(find.text('Player_1'), findsOneWidget);
    expect(find.text('Player_2'), findsOneWidget);

    // Check size of the LudoBoardWidget to ensure it didn't collapse to 0
    final boardSize = tester.getSize(find.byType(LudoBoardWidget));
    expect(boardSize.width, greaterThan(0));
    expect(boardSize.height, greaterThan(0));
    expect(boardSize.width, equals(boardSize.height)); // Should be a square
  });
}
