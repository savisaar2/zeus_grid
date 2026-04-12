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
