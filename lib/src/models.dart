import 'package:flutter/material.dart';

@immutable // 🎯 Signal to the IDE that this shouldn't change
class ZeusModule {
  final String id;
  final int x;
  final int y;
  final int w;
  final int h;
  final int minW;
  final int minH;

  const ZeusModule({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.minW = 1,
    this.minH = 1,
  });

  // 🎯 The "Professional" way to update models in Flutter
  ZeusModule copyWith({int? x, int? y, int? w, int? h, int? minW, int? minH}) {
    return ZeusModule(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      minW: minW ?? this.minW,
      minH: minH ?? this.minH,
    );
  }

  // Legacy support for your current copy() call
  ZeusModule copy() => copyWith();
}

enum ZeusHandle {
  move,
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ZeusSession {
  final String id;
  final ZeusModule preview;
  final Offset anchor;
  final ZeusHandle handle;
  final bool isValid;
  final bool isFromDrawer;
  final bool isOverGrid;
  final int initialGridX;
  final int initialGridY;
  final int initialW;
  final int initialH;
  final int initialX;
  final int initialY;

  const ZeusSession({
    required this.id,
    required this.preview,
    required this.anchor,
    required this.handle,
    this.isValid = true,
    this.isFromDrawer = false,
    this.isOverGrid = false,
    this.initialGridX = 0,
    this.initialGridY = 0,
    this.initialW = 0,
    this.initialH = 0,
    this.initialX = 0,
    this.initialY = 0,
  });

  ZeusSession copyWith({ZeusModule? preview, bool? isOverGrid, bool? isValid}) {
    return ZeusSession(
      id: id,
      preview: preview ?? this.preview,
      anchor: anchor,
      handle: handle,
      isFromDrawer: isFromDrawer,
      isOverGrid: isOverGrid ?? this.isOverGrid,
      isValid: isValid ?? this.isValid,
      initialGridX: initialGridX,
      initialGridY: initialGridY,
      initialW: initialW,
      initialH: initialH,
      initialX: initialX,
      initialY: initialY,
    );
  }
}

class GridStyle {
  final Color backgroundColor;
  final Color lineColor;
  final Color majorLineColor;
  final double lineWidth;
  final double majorLineWidth;
  final int minorInterval;
  final int majorInterval;
  final bool showGrid;

  const GridStyle({
    this.backgroundColor = const Color(0xFF080808),
    this.lineColor = const Color.fromARGB(25, 255, 255, 255),
    this.majorLineColor = const Color.fromARGB(60, 255, 255, 255),
    this.lineWidth = 1.0,
    this.majorLineWidth = 1.0,
    this.minorInterval = 2,
    this.majorInterval = 10,
    this.showGrid = true,
  });
}

class ModuleStyle {
  final Color color;
  final Color activeBorderColor;
  final Color warningBorderColor;
  final BorderRadius borderRadius;
  final double elevation;
  final double activeOpacity;
  final double borderWidth; // 🎯 Added for extra customization

  const ModuleStyle({
    this.color = const Color(0xFF0A0A0A),
    this.activeBorderColor = Colors.cyanAccent,
    this.warningBorderColor = Colors.redAccent,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.elevation = 2.0,
    this.activeOpacity = 0.8,
    this.borderWidth = 1.0,
  });
}

class ZeusMenuStyle {
  final String title;
  final TextStyle titleStyle;
  final Color backgroundColor;
  final double width;
  final Curve animationCurve;
  final Duration animationDuration;

  const ZeusMenuStyle({
    this.title = "ARSENAL",
    this.titleStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
      fontSize: 12,
    ),
    this.backgroundColor = const Color(0xFF080808),
    this.width = 280.0,
    this.animationCurve = Curves.easeOutQuart,
    this.animationDuration = const Duration(milliseconds: 300),
  });
}
