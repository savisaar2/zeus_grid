# ZeusGrid: Technical Context & Guidelines

ZeusGrid is a Flutter package providing a normalized, tactical grid engine for building high-density, interactive dashboards. It uses a state-driven approach with a "living canvas" that scales proportionally across different screen sizes.

## Project Overview

- **Core Technology:** Flutter/Dart.
- **Purpose:** High-performance dashboard engine with fixed logical positioning (tactical map) rather than responsive reflowing.
- **Key Features:**
    - Smart proportional scaling.
    - Multi-axis resizing (planned/implemented via sessions).
    - Drag-and-dock interaction with collision detection.
    - "Arsenal" (side menu) for unplaced modules.
    - Unidirectional Data Flow architecture.

## Architecture & State Management

- **Single Source of Truth:** The parent widget/application manages the list of `modules` and `unplacedModules`.
- **Interactions:** The `ZeusGrid` widget uses a `ValueNotifier<ZeusSession?>` to track active drag/resize operations.
- **Callbacks:**
    - `onModuleUpdate(ZeusModule)`: Fired when a module is moved or resized.
    - `onModuleRemove(String id)`: Fired when a module is deleted from the grid.
    - `onGenerateContent(String id)`: Builder function for module content.
- **Collision Detection:** Implemented in `_ZeusGridState._collision` using Axis-Aligned Bounding Box (AABB) logic.

## Key Files & Directories

- `lib/zeus_grid.dart`: The primary widget entry point and interaction logic.
- `lib/src/models.dart`: Core data models (`ZeusModule`, `GridStyle`, `ModuleStyle`, `ZeusMenuStyle`).
- `lib/src/grid_painter.dart`: Custom painter for the background grid lines.
- `test/`: Contains unit tests for grid logic (e.g., boundary clamping, collision).
- `example/`: A full implementation example showing state persistence and integration.

## Development Workflows

### Setup & Dependencies
```powershell
flutter pub get
```

### Running Tests
```powershell
flutter test
```

### Running the Example
```powershell
cd example
flutter run
```

## Coding Conventions

- **Immutability:** `ZeusModule` is immutable; always use `.copyWith()` for updates.
- **Logical Units:** All positioning (`x`, `y`) and sizing (`w`, `h`) are in logical grid units (default 120x100), not physical pixels.
- **Styling:** Adhere to the `GridStyle`, `ModuleStyle`, and `ZeusMenuStyle` patterns for UI customization.
- **Linting:** Follows `flutter_lints` standards as defined in `analysis_options.yaml`.

## TODOs / Roadmap (Inferred)
- [ ] Implement multi-axis resizing "grab bars" (mentioned in README, logic for `h`/`w` updates in `_updateSession` needs verification).
- [ ] Enhancing collision feedback (Cyan for valid, Red for collision).
- [ ] Formalizing the "Arsenal" animation and docking logic.
