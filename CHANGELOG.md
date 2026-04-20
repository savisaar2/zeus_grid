## 1.2.0 - Responsive & Performance Update

* **New Feature: Responsive Columns** - Added `columns` parameter to `ZeusGrid`. When set, the grid automatically calculates cell dimensions based on available width, allowing for responsive column-based layouts (e.g., a "4-column grid") that adapt to window resizing.
* **Performance: ValueNotifier Architecture** - Refactored `_focusedModuleId` and active sessions to use `ValueNotifier` and `ValueListenableBuilder`. This enables surgical rebuilds of only the affected modules, significantly reducing the overhead on the main widget tree during hover and drag operations.
* **UX: Explicit Arsenal Docking** - Improved module removal logic. Modules now only return to the Arsenal when explicitly dragged over the sidebar.
* **UX: Edge Snapping** - Dragging a module outside the window bounds (anywhere except the sidebar) now correctly snaps it to the last valid edge position instead of removing it.
* **Stability: Resource Management** - Implemented `dispose()` method in `ZeusGrid` state to properly cleanup all internal notifiers, preventing potential memory leaks in complex applications.
* **Fix: Out-of-bounds Resizing** - Fixed a bug where resizing a module past the window edge would cause it to be incorrectly removed from the grid.

## 1.1.0 - Tactical Expansion

* **New Feature: Max Constraints** - Added `maxW` and `maxH` to `ZeusModule`. Dashboards can now enforce maximum sizes for widgets.
* **New Feature: Multi-directional Gravity** - Introduced `PackDirection` support (`up`, `down`, `left`, `right`). Auto-packing now supports advanced flow patterns beyond simple downward gravity.
* **New Feature: Customizable Resize Handles** - Added `resizeHandleBuilder` to `ModuleStyle`. Developers can now fully theme and replace the resize anchors.
* **New Feature: Collision Callbacks** - Added `onCollisionDetected` callback to `ZeusGrid`, allowing host apps to react to invalid placements (e.g., showing a warning toast).
* **Performance: Granular Rebuild Architecture** - Optimized the grid stack to rebuild only the actively moving module and its neighbors, preventing full-stack rebuilds during high-frequency drag events.
* **Performance: Optimized Layout Resizing** - The grid now intelligently skips layout recalculations when the viewport expands, only triggering bounds-pushing logic during shrinking.
* **UX: Ghost Drag Fill** - Ghost previews now feature a translucent semi-transparent fill for better visibility.
* **UX: Persistent Visibility** - Modules no longer disappear when dragged past the window edges or over the arsenal menu.
* **Fix: Consistency Fix** - Standardized all grid calculations to use strict `.floor()` logic, eliminating edge-case "rubber-banding" glitches.

## 1.0.0 - Production Grade Release

* **New Feature: Auto-packing / Collision Resolution** - Modules now dynamically "push" each other out of the way during drag and resize operations, ensuring a valid layout at all times.
* **New Feature: Ghost Preview & Smooth Snapping** - Implemented pixel-perfect visual tracking. Modules follow the cursor smoothly while a "Ghost" outline shows the grid-snapped landing spot. Includes a polished 150ms snap animation upon release.
* **New Feature: State Serialization** - Added `toJson()` and `ZeusModule.fromJson()` support, making it easy to save and load custom dashboard layouts.
* **Performance: Layered Rendering Architecture** - Decoupled high-frequency movement updates from the static grid, drastically reducing the widget rebuild count.
* **Performance: Repaint Boundary Isolation** - Isolated the grid background, individual modules, and arsenal drawer into separate GPU layers to minimize repaint overhead.
* **Performance: Widget Granularity** - Refactored module rendering into granular `StatelessWidget` classes to leverage Flutter's internal caching and skip unnecessary widget-tree diffing.
* **Performance: Hit-Testing Optimization** - Implemented an interaction lock that disables hit-testing for background modules during active drag sessions, reducing input latency.
* **Visuals: Advanced Tactical Feedback** - Added dynamic shadows and "tactical glows" to active modules.
* **Visuals: Smooth Style Transitions** - Refactored module cards to use `AnimatedContainer` for fluid background, border, and shadow changes.
* **Fix: Interaction Stability** - Resolved flickering during module hover/focus changes and fixed "flashing" warning states during boundary violations.

## 0.9.0

* **Breaking Change**: Simplified the grid system to an exclusive fixed 1:1 pixel-to-unit architecture.
* **Breaking Change**: Removed `useFixedGrid`, `columns`, and `rows` parameters from `ZeusGrid`.
* **New Feature**: Added `cellSide` parameter to control grid density (1 unit = `cellSide` pixels).
* **New Feature**: Implemented Viewport Boundary Pushing – modules are automatically pushed back into bounds if the viewport shrinks.
* **New Feature**: Added dynamic grid expansion – the grid now automatically fills the entire viewport without skewing.
* **Enhancement**: Precision resizing – fixed coordinate rounding issues for pixel-perfect handle tracking.
* **Enhancement**: Improved "Maths-Page" grid aesthetics with configurable minor and major lines.
* **UX**: Enhanced resize handle hit testing and interaction priority.
* **UX**: Added movement threshold to prevent accidental module removals.

## 0.8.6

* Initial support for multi-axis resizing.
* Added "Arsenal" side drawer for unplaced modules.
* Implemented collision detection and visual feedback.
