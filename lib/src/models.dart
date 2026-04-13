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
  final int? maxW;
  final int? maxH;

  const ZeusModule({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.minW = 1,
    this.minH = 1,
    this.maxW,
    this.maxH,
  });

  // 🎯 The "Professional" way to update models in Flutter
  ZeusModule copyWith({
    int? x,
    int? y,
    int? w,
    int? h,
    int? minW,
    int? minH,
    int? maxW,
    int? maxH,
  }) {
    return ZeusModule(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      minW: minW ?? this.minW,
      minH: minH ?? this.minH,
      maxW: maxW ?? this.maxW,
      maxH: maxH ?? this.maxH,
    );
  }

  // Legacy support for your current copy() call
  ZeusModule copy() => copyWith();

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'minW': minW,
        'minH': minH,
        'maxW': maxW,
        'maxH': maxH,
      };

  factory ZeusModule.fromJson(Map<String, dynamic> json) => ZeusModule(
        id: json['id'] as String,
        x: json['x'] as int,
        y: json['y'] as int,
        w: json['w'] as int,
        h: json['h'] as int,
        minW: (json['minW'] ?? 1) as int,
        minH: (json['minH'] ?? 1) as int,
        maxW: json['maxW'] as int?,
        maxH: json['maxH'] as int?,
      );
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

enum PackDirection {
  up,
  down,
  left,
  right,
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
  final Offset visualPosition;
  final Size visualSize;

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
    this.visualPosition = Offset.zero,
    this.visualSize = Size.zero,
  });

  ZeusSession copyWith({
    ZeusModule? preview,
    bool? isOverGrid,
    bool? isValid,
    Offset? visualPosition,
    Size? visualSize,
  }) {
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
      visualPosition: visualPosition ?? this.visualPosition,
      visualSize: visualSize ?? this.visualSize,
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
    this.lineColor = const Color.fromARGB(15, 255, 255, 255),
    this.majorLineColor = const Color.fromARGB(35, 255, 255, 255),
    this.lineWidth = 1.0,
    this.majorLineWidth = 1.0,
    this.minorInterval = 1,
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
  final List<BoxShadow>? baseShadow;
  final List<BoxShadow>? activeShadow;

  const ModuleStyle({
    this.color = const Color(0xFF0A0A0A),
    this.activeBorderColor = Colors.cyanAccent,
    this.warningBorderColor = Colors.redAccent,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.elevation = 2.0,
    this.activeOpacity = 0.8,
    this.borderWidth = 1.0,
    this.baseShadow,
    this.activeShadow = const [
      BoxShadow(
        color: Color(0x3300FFFF),
        blurRadius: 15,
        spreadRadius: 2,
      )
    ],
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
