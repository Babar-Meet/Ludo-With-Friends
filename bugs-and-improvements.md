# Ludo With Friends — Bugs & Improvements

## 1. Dice Size
- Current: 32px cube (tiny)
- Request: Make it much bigger (64px = 2x linear)
- On web, the 3D dice face white background sometimes renders transparent (only dots visible) — likely a Chrome/web rendering quirk, works fine on mobile

## 2. Token Tap Issue (2-4 presses to move)
- Tokens need multiple taps before they register
- Likely cause: tap target area too small (below Flutter's 48dp minimum)
- Fix: increase GestureDetector hit area with padding for movable tokens, use `HitTestBehavior.opaque`

## 3. Token Disappears at Home (position 56)
- When a token completes its circuit and reaches home (position 56), it disappears from the board
- Cause: `getCoordinate()` returns `null` for position 56, and `_buildTokensOverlay` filters out `isFinished` tokens
- Fix: render finished tokens in home base center area

## 4. Chopi Animation Laggy / Frame Skipping
- The hopping token animation uses `setState()` on every animation frame, rebuilding the entire widget
- Fix: use `AnimatedBuilder` instead, pre-compute `sin(t*pi)` once

## 5. Winner Still Gets Turns After Winning
- When all 4 tokens of a player reach home, the winner still gets extra turns (dice shows for them)
- They should be skipped from the turn cycle

## 6. Winner Dialog Blocks Game for Remaining Players
- Current: winner dialog pops up immediately when a player wins
- Request: show only a toast ("Player X finished 1st!"), let remaining players continue playing
- Only show final ranking dialog when only 1 player remains unfinished

## 7. No Ranking System
- No 2nd, 3rd, 4th place tracking
- Request: track finish order, show ranking with medals (🥇🥈🥉) when game ends

## 8. Player Corner Layout
- Current: name + settings on top row, avatar|dice on bottom row (horizontal)
- Considered vertical layout: dice → name → avatar+settings (but reverted)

## 9. Gold Border / Glow Around Player Area
- Amber border and glow around the active player's corner looked bad
- Cleaner without boxes/borders around everything

## 10. Ranking Badge for Finished Players
- Replace dice with a rank badge (gold/silver/bronze medal icon + "1st"/"2nd"/etc.)
