import 'package:flutter/material.dart';

@immutable // 🎯 Signal to the IDE that this shouldn't change
class ZeusModule {
  final String id;
  final int x;
  final int y;
  final int w;
  final int h;

  const ZeusModule({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  // 🎯 The "Professional" way to update models in Flutter
  ZeusModule copyWith({int? x, int? y, int? w, int? h}) {
    return ZeusModule(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }

  // Legacy support for your current copy() call
  ZeusModule copy() => copyWith();
}

enum HandleType {
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
  final HandleType handle;
  final bool isValid;
  final bool isFromDrawer;
  final bool isOverGrid;

  const ZeusSession({
    required this.id,
    required this.preview,
    required this.anchor,
    required this.handle,
    this.isValid = true,
    this.isFromDrawer = false,
    this.isOverGrid = false,
  });
}

class GridStyle {
  final Color lineColor;
  final double lineWidth;
  final bool showGrid;

  const GridStyle({
    this.lineColor = const Color.fromARGB(13, 255, 255, 255),
    this.lineWidth = 0.5,
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
