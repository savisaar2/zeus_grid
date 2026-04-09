# ZeusGrid Development Guide

## Project Overview
Flutter package for tactical grid-based dashboards. Grid coordinates are logical units (default 120x100), not pixels.

## Commands
```bash
flutter pub get    # Install dependencies
flutter test       # Run all tests
flutter analyze    # Lint/typecheck
cd example && flutter run  # Run example app
```

## Architecture
- **Entry point**: `lib/zeus_grid.dart` (exports models)
- **Core models**: `lib/src/models.dart` (`ZeusModule`, `ZeusSession`, `GridStyle`, `ModuleStyle`, `ZeusMenuStyle`)
- **Grid rendering**: `lib/src/grid_painter.dart`
- **State**: Parent widget owns `modules`/`unplacedModules` lists; `ZeusGrid` uses `ValueNotifier<ZeusSession?>` for active drag/resize

## Key Conventions
- `ZeusModule` is **immutable** - always use `.copyWith()` for updates
- `ZeusModule.copy()` returns a shallow copy (all fields equal)
- Collision detection: AABB in `_collision()` method
- Resize handles use `ZeusHandle` enum (move, top, bottom, left, right, topRight, bottomRight, bottomLeft)
- Grid lines only render when `isEditing: true`

## Module Structure
Modules have 30px padding for handles. The structure is:
```
Positioned (outer - 30px padding area)
└── MouseRegion (full module area for focus tracking)
    └── Stack
        └── Positioned (left: 30, top: 30 - card)
            └── SizedBox (cardW × cardH)
                └── _buildCard (card content)
        └── _buildResizeHandle (on card edges, may extend into padding area)
        └── Close button (top-right corner, outside card)
```

## Handle Sizing
- Corner handles: 24×24px (centered on corner, may extend into padding)
- Edge handles: 8×30px or 30×8px (on edge)
- Handles have no visible background (transparent)
- Outer MouseRegion maintains focus when hovering over handles

## Testing Notes
- Tests use `PointerDeviceKind.mouse` - import `dart:ui`
- Interaction tests require `await gesture.addPointer(location: Offset.zero)` before `moveTo()`
- Widget tests need `await tester.pump()` after mouse hover to trigger `_focusedModuleId`

## File Structure
```
lib/
  zeus_grid.dart       # Main widget, exports src/models.dart
  src/
    models.dart        # Data models
    grid_painter.dart  # CustomPainter for grid lines
test/
  grid_logic_test.dart        # Boundary/clamping tests
  grid_interaction_test.dart  # Widget interaction tests (18 tests)
example/lib/main.dart  # Full integration example
```

## Current State
- All 18 tests pass
- Focus is lost when mouse exits module bounds (outer MouseRegion)
- Handles are transparent (no visible box)
- Handles are positioned at module edges (24×24 corners, 8×30 or 30×8 edges)
- Focus does not flicker when hovering over handles
