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
