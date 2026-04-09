# ZeusGrid: Tactical Dashboard Engine

ZeusGrid is a high-performance Flutter package for building high-density, interactive dashboards. Unlike responsive layouts that "reflow" content, ZeusGrid treats the screen as a **tactical map** with a persistent 1:1 grid, allowing for pixel-perfect placement and mathematical consistency.

![Main Page](assets/front_page.png)

## Features

### 📐 Persistent 1:1 Grid (Maths-Page Architecture)
The grid acts as a stable foundation. Instead of scaling or skewing when the window is resized, the grid dynamically adds or removes columns and rows to fill the available space. This ensures your data monitors always maintain their intended aspect ratio and size.

### 🛡️ Viewport Boundary Pushing
If the app viewport shrinks, ZeusGrid automatically detects which modules would be clipped and "pushes" them back into the visible boundary. Your layout adapts intelligently to protect your data visibility without distorting the grid.

### 🎯 Precision Multi-Axis Resizing
- **Grab Bars:** Subtle visual handles on every side and corner allow for intuitive stretching and shrinking.
- **Smart Hit Areas:** Large, translucent hit areas ensure that resizing is effortless, while still allowing the module to be dragged from almost anywhere.
- **Visual Feedback:** Real-time feedback tints—**Cyan** for valid placement and **Red** for collisions.

### 🏗️ State-Driven "Arsenal" System
The "Arsenal" is a sleek, animated side drawer for unplaced modules. It is fully grid-aware:
- **Drag-to-Dock:** Drag an active module into the Arsenal to un-dock it.
- **Auto-Sync:** Modules disappear from the menu when placed on the grid and return instantly when removed.

## Getting Started

### 1. Define Your Modules

```dart
// Modules currently displayed on the grid
List<ZeusModule> myModules = [
  ZeusModule(id: 'cpu_monitor', x: 10, y: 10, w: 40, h: 30, minW: 20, minH: 15),
];

// Modules waiting in the "Arsenal" side menu
List<ZeusModule> myArsenal = [
  ZeusModule(id: 'network_graph', x: 0, y: 0, w: 80, h: 30, minW: 40, minH: 20),
];
```

### 2. Initialize the ZeusGrid

```dart
ZeusGrid(
  isEditing: _isEditMode,
  cellSide: 10.0, // 🎯 1 unit = 10 physical pixels
  modules: myModules,
  unplacedModules: myArsenal,
  onGenerateContent: (id) => MyModuleWidget(id),
  onModuleUpdate: (m) => setState(() => updateSourceOfTruth(m)),
  onModuleRemove: (id) => setState(() => removeFromGrid(id)),
);
```

## Customization

### Styling
Customize the look and feel of your dashboard using dedicated style objects.

```dart
ZeusGrid(
  gridStyle: GridStyle(
    backgroundColor: Color(0xFF080808),
    lineColor: Colors.white.withAlpha(15),
    majorLineColor: Colors.white.withAlpha(35),
    majorInterval: 10, // Brighter line every 10 units
  ),
  moduleStyle: ModuleStyle(
    color: Color(0xFF0A0A0A),
    borderRadius: BorderRadius.circular(4),
    activeBorderColor: Colors.cyanAccent,
  ),
);
```

## Extending ZeusGrid

### Unidirectional Data Flow
ZeusGrid follows a strict state-driven pattern. It does not manage its own internal list of modules. Instead, it notifies your application of changes, allowing you to integrate with any state management solution (Riverpod, Bloc, Provider) or sync directly to a database.

#### `onModuleUpdate(ZeusModule module)`
Fires whenever a module is moved or resized. Use this to update your backend or local state.

#### `onModuleRemove(String id)`
Fires when a module is closed or dragged into the Arsenal. Use this to move the module ID from your "active" list back to your "unplaced" list.

## Why ZeusGrid?
Dashboard packages often struggle with "layout reflow" which can be disorienting in high-stakes monitoring environments. ZeusGrid was built to solve this by providing a **fixed tactical map** where data is always exactly where you left it.

---

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/savisaar2d)
