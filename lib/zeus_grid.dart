import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'src/models.dart';
import 'src/grid_painter.dart';

export 'src/models.dart';

class ZeusGrid extends StatefulWidget {
  final List<ZeusModule> modules, unplacedModules;
  final bool isEditing;
  final Widget Function(String id) onGenerateContent;
  final Function(ZeusModule) onModuleUpdate;
  final Function(String) onModuleRemove;
  final Function(ZeusModule collision)? onCollisionDetected;
  final GridStyle gridStyle;
  final ModuleStyle moduleStyle;
  final ZeusMenuStyle menuStyle;
  final double cellSide;
  final int? columns;
  final bool autoPack;
  final PackDirection packDirection;

  const ZeusGrid({
    super.key,
    required this.modules,
    required this.unplacedModules,
    required this.isEditing,
    required this.onGenerateContent,
    required this.onModuleUpdate,
    required this.onModuleRemove,
    this.onCollisionDetected,
    this.gridStyle = const GridStyle(),
    this.moduleStyle = const ModuleStyle(),
    this.menuStyle = const ZeusMenuStyle(),
    this.cellSide = 10.0,
    this.columns,
    this.autoPack = false,
    this.packDirection = PackDirection.down,
  });

  @override
  State<ZeusGrid> createState() => _ZeusGridState();
}

const double _kHandleLength = 15.0;
const double _kHandleThickness = 2.0;
const double _kHitAreaSize = 40.0;
const double _kHandleInset = 10.0;

class _ZeusGridState extends State<ZeusGrid> {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<ZeusSession?> _activeSession = ValueNotifier(null);
  final ValueNotifier<String?> _activeSessionId = ValueNotifier(null);
  final ValueNotifier<List<ZeusModule>?> _packedModules = ValueNotifier(null);
  final ValueNotifier<String?> _focusedModuleId = ValueNotifier(null);
  Offset? _lastMousePosition;
  Size? _lastSize;

  @override
  void dispose() {
    _activeSession.dispose();
    _activeSessionId.dispose();
    _packedModules.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastSize != null && _lastSize != size) {
          final oldSize = _lastSize!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pushModulesIntoBounds(size, oldSize);
          });
        }
        _lastSize = size;

        final double cellW = widget.columns != null ? constraints.maxWidth / widget.columns! : widget.cellSide;
        final double cellH = widget.columns != null ? cellW : widget.cellSide;

        final cols = widget.columns ?? (constraints.maxWidth / widget.cellSide).floor();
        final rows = (constraints.maxHeight / cellH).floor();

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _updateSession,
          onPointerUp: (_) => _endSession(),
          onPointerCancel: (_) {
            _activeSession.value = null;
            _activeSessionId.value = null;
            _packedModules.value = null;
          },
          child: Stack(
            children: [
              Container(color: widget.gridStyle.backgroundColor),
              _buildVirtualGrid(cellW, cellH, cols, rows),
              _buildArsenalDrawer(widget.isEditing, cellW, cellH),
            ],
          ),
        );
      },
    );
  }

  void _pushModulesIntoBounds(Size size, Size oldSize) {
    final double cellW = widget.columns != null ? size.width / widget.columns! : widget.cellSide;
    final double cellH = widget.columns != null ? cellW : widget.cellSide;

    final cols = widget.columns ?? (size.width / widget.cellSide).floor();
    final rows = (size.height / cellH).floor();

    final double oldCellW = widget.columns != null ? oldSize.width / widget.columns! : widget.cellSide;
    final double oldCellH = widget.columns != null ? oldCellW : widget.cellSide;

    final lastCols = widget.columns ?? (oldSize.width / widget.cellSide).floor();
    final lastRows = (oldSize.height / oldCellH).floor();

    // Optimization: only push if bounds shrank
    if (cols >= lastCols && rows >= lastRows) return;

    for (var m in widget.modules) {
      int newX = m.x;
      int newY = m.y;
      bool pushed = false;

      if (m.x + m.w > cols) {
        newX = (cols - m.w).clamp(0, cols);
        pushed = true;
      }
      if (m.y + m.h > rows) {
        newY = (rows - m.h).clamp(0, rows);
        pushed = true;
      }

      if (pushed) {
        widget.onModuleUpdate(m.copyWith(x: newX, y: newY));
      }
    }
  }

  Widget _buildVirtualGrid(double cellW, double cellH, int cols, int rows) {
    return SizedBox.expand(
      child: Stack(
        key: _gridKey,
        clipBehavior: Clip.none,
        children: [
          if (widget.isEditing)
            Positioned.fill(
              child: ZeusGridBackground(
                style: widget.gridStyle,
                cellW: cellW,
                cellH: cellH,
                rows: rows,
                cols: cols,
              ),
            ),
          ...widget.modules.map((m) {
            return ValueListenableBuilder<String?>(
              valueListenable: _focusedModuleId,
              builder: (context, focusedId, _) {
                return _ModuleWrapper(
                  key: ValueKey('module_wrapper_${m.id}'),
                  initialModule: m,
                  activeSessionId: _activeSessionId,
                  activeSession: _activeSession,
                  packedModules: _packedModules,
                  isEditing: widget.isEditing,
                  isFocused: widget.isEditing && focusedId == m.id,
                  cellW: cellW,
                  cellH: cellH,
                  moduleStyle: widget.moduleStyle,
                  content: widget.onGenerateContent(m.id),
                  onStartSession: _startSession,
                  onRemove: () => widget.onModuleRemove(m.id),
                  onFocusChange: (id) => _focusedModuleId.value = id,
                );
              },
            );
          }),
          // Active module ghost and smooth preview
          ValueListenableBuilder<ZeusSession?>(
            valueListenable: _activeSession,
            builder: (context, session, _) {
              if (session == null) {
                return const SizedBox.shrink();
              }

              // Only hide if it's a new module from drawer and it's not over the grid
              if (session.isFromDrawer && !session.isOverGrid) {
                return const SizedBox.shrink();
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildGhost(session.preview, session.isValid, cellW, cellH),
                  ZeusModuleWidget(
                    key: ValueKey('module_active_${session.id}'),
                    module: session.preview,
                    session: session,
                    isEditing: widget.isEditing,
                    isFocused: true,
                    cellW: cellW,
                    cellH: cellH,
                    moduleStyle: widget.moduleStyle,
                    content: widget.onGenerateContent(session.id),
                    onStartSession: _startSession,
                    onRemove: () => widget.onModuleRemove(session.id),
                    onFocusChange: (id) =>
                        _focusedModuleId.value = id,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGhost(ZeusModule m, bool isValid, double cellW, double cellH) {
    final color = isValid ? Colors.cyanAccent : Colors.redAccent;
    return Positioned(
      left: m.x * cellW,
      top: m.y * cellH,
      width: m.w * cellW,
      height: m.h * cellH,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            border: Border.all(color: color.withAlpha(100), width: 2),
            borderRadius: widget.moduleStyle.borderRadius,
          ),
        ),
      ),
    );
  }

  void _startSession(
    ZeusModule m,
    PointerDownEvent e,
    bool fromDrawer, {
    ZeusHandle handle = ZeusHandle.move,
  }) {
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final double cellW = widget.columns != null ? rb.size.width / widget.columns! : widget.cellSide;
    final double cellH = widget.columns != null ? cellW : widget.cellSide;
    final local = rb.globalToLocal(e.position);

    final double visualW = (m.w * cellW).clamp(m.minW * cellW, double.infinity);
    final double visualH = (m.h * cellH).clamp(m.minH * cellH, double.infinity);

    Offset anchor;
    int initialGridX = m.x;
    int initialGridY = m.y;

    if (fromDrawer) {
      anchor = Offset(visualW / 2, visualH / 2);
    } else if (handle == ZeusHandle.move) {
      // If a handle already started a resize session (which fires first as innermost),
      // don't overwrite it with a move session.
      if (_activeSession.value != null) return;
      anchor = local - Offset(m.x * cellW, m.y * cellH);
    } else {
      anchor = local;
      initialGridX = (local.dx / cellW).floor();
      initialGridY = (local.dy / cellH).floor();
    }

    _activeSession.value = ZeusSession(
      id: m.id,
      preview: m.copy(),
      anchor: anchor,
      isFromDrawer: fromDrawer,
      handle: handle,
      isOverGrid: !fromDrawer,
      initialGridX: initialGridX,
      initialGridY: initialGridY,
      initialW: m.w,
      initialH: m.h,
      initialX: m.x,
      initialY: m.y,
      visualPosition: Offset(m.x * cellW, m.y * cellH),
      visualSize: Size(visualW, visualH),
    );
    _activeSessionId.value = m.id;
    _focusedModuleId.value = m.id;
    _lastMousePosition = rb.globalToLocal(e.position);
  }

  void _updateSession(PointerMoveEvent e) {
    final s = _activeSession.value;
    if (s == null) return;
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final double cellW = widget.columns != null ? rb.size.width / widget.columns! : widget.cellSide;
    final double cellH = widget.columns != null ? cellW : widget.cellSide;

    final cols = widget.columns ?? (rb.size.width / widget.cellSide).floor();
    final rows = (rb.size.height / cellH).floor();

    final local = rb.globalToLocal(e.position);
    _lastMousePosition = local;

    bool overGrid =
        local.dx >= -40 &&
        local.dx <= (rb.size.width + 40) &&
        local.dy >= -40 &&
        local.dy <= (rb.size.height + 40);

    bool isOverArsenal = false;
    if (widget.isEditing) {
      if (local.dx >= (rb.size.width - widget.menuStyle.width)) {
        isOverArsenal = true;
      }
    }

    if (widget.isEditing && s.isFromDrawer) {
      // Must be significantly over the arsenal drawer to trigger removal (e.g. 100px in)
      if (local.dx >= (rb.size.width - widget.menuStyle.width + 100)) {
        overGrid = false;
      }
    }

    ZeusModule p = s.preview;

    Offset vPos = s.visualPosition;
    Size vSize = s.visualSize;

    switch (s.handle) {
      case ZeusHandle.move:
        final t = local - s.anchor;
        vPos = t;
        p = s.preview.copyWith(
          x: (t.dx / cellW).round().clamp(0, cols - s.preview.w),
          y: (t.dy / cellH).round().clamp(0, rows - s.preview.h),
        );
        break;
      case ZeusHandle.right:
        final double deltaX = local.dx - s.initialGridX * cellW;
        vSize = Size(
          (s.initialW * cellW + deltaX).clamp(
            s.preview.minW * cellW,
            (s.preview.maxW ?? cols).toDouble() * cellW,
          ),
          vSize.height,
        );
        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          (s.preview.maxW ?? (cols - p.x)).clamp(0, cols - p.x),
        );
        p = p.copyWith(w: snappedW);
        break;
      case ZeusHandle.left:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double rawX = s.initialX * cellW + deltaX;
        final double rawW = s.initialW * cellW - deltaX;

        final double minW = s.preview.minW * cellW;
        final double maxW =
            (s.preview.maxW ?? (s.initialX + s.initialW)).toDouble() * cellW;

        if (rawW < minW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - minW),
            vPos.dy,
          );
          vSize = Size(minW, vSize.height);
        } else if (rawW > maxW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - maxW),
            vPos.dy,
          );
          vSize = Size(maxW, vSize.height);
        } else {
          vPos = Offset(rawX.clamp(0, double.infinity), vPos.dy);
          vSize = Size(rawW, vSize.height);
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          math.max(
            0,
            s.initialX +
                s.initialW -
                (s.preview.maxW ?? s.initialX + s.initialW),
          ),
          s.initialX + s.initialW - s.preview.minW,
        );
        p = p.copyWith(x: snappedX, w: s.initialX + s.initialW - snappedX);
        break;
      case ZeusHandle.bottom:
        final double deltaY = local.dy - s.initialGridY * cellH;
        vSize = Size(
          vSize.width,
          (s.initialH * cellH + deltaY).clamp(
            s.preview.minH * cellH,
            (s.preview.maxH ?? rows).toDouble() * cellH,
          ),
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          (s.preview.maxH ?? (rows - s.initialY)).clamp(0, rows - s.initialY),
        );
        p = p.copyWith(h: snappedH);
        break;
      case ZeusHandle.top:
        final double deltaY = local.dy - s.initialGridY * cellH;
        final double rawY = s.initialY * cellH + deltaY;
        final double rawH = s.initialH * cellH - deltaY;

        final double minH = s.preview.minH * cellH;
        final double maxH =
            (s.preview.maxH ?? (s.initialY + s.initialH)).toDouble() * cellH;

        if (rawH < minH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - minH),
          );
          vSize = Size(vSize.width, minH);
        } else if (rawH > maxH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - maxH),
          );
          vSize = Size(vSize.width, maxH);
        } else {
          vPos = Offset(vPos.dx, rawY.clamp(0, double.infinity));
          vSize = Size(vSize.width, rawH);
        }

        final int snappedY = (vPos.dy / cellH).round().clamp(
          math.max(
            0,
            s.initialY +
                s.initialH -
                (s.preview.maxH ?? s.initialY + s.initialH),
          ),
          s.initialY + s.initialH - s.preview.minH,
        );
        p = p.copyWith(y: snappedY, h: s.initialY + s.initialH - snappedY);
        break;
      case ZeusHandle.bottomRight:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;
        vSize = Size(
          (s.initialW * cellW + deltaX).clamp(
            s.preview.minW * cellW,
            (s.preview.maxW ?? cols).toDouble() * cellW,
          ),
          (s.initialH * cellH + deltaY).clamp(
            s.preview.minH * cellH,
            (s.preview.maxH ?? rows).toDouble() * cellH,
          ),
        );
        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          (s.preview.maxW ?? (cols - s.initialX)).clamp(0, cols - s.initialX),
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          (s.preview.maxH ?? (rows - s.initialY)).clamp(0, rows - s.initialY),
        );
        p = p.copyWith(w: snappedW, h: snappedH);
        break;
      case ZeusHandle.topRight:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;

        vSize = Size(
          (s.initialW * cellW + deltaX).clamp(
            s.preview.minW * cellW,
            (s.preview.maxW ?? cols).toDouble() * cellW,
          ),
          (s.initialH * cellH - deltaY).clamp(
            s.preview.minH * cellH,
            (s.preview.maxH ?? (s.initialY + s.initialH)).toDouble() * cellH,
          ),
        );

        final double minH = s.preview.minH * cellH;
        final double maxH =
            (s.preview.maxH ?? (s.initialY + s.initialH)).toDouble() * cellH;

        if ((s.initialH * cellH - deltaY) < minH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - minH),
          );
        } else if ((s.initialH * cellH - deltaY) > maxH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - maxH),
          );
        } else {
          vPos = Offset(
            vPos.dx,
            (s.initialY * cellH + deltaY).clamp(0, double.infinity),
          );
        }

        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          (s.preview.maxW ?? (cols - s.initialX)).clamp(0, cols - s.initialX),
        );
        final int snappedY = (vPos.dy / cellH).round().clamp(
          math.max(
            0,
            s.initialY +
                s.initialH -
                (s.preview.maxH ?? s.initialY + s.initialH),
          ),
          s.initialY + s.initialH - s.preview.minH,
        );
        p = p.copyWith(
          w: snappedW,
          y: snappedY,
          h: s.initialY + s.initialH - snappedY,
        );
        break;
      case ZeusHandle.topLeft:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;

        final double minW = s.preview.minW * cellW;
        final double maxW =
            (s.preview.maxW ?? (s.initialX + s.initialW)).toDouble() * cellW;
        final double minH = s.preview.minH * cellH;
        final double maxH =
            (s.preview.maxH ?? (s.initialY + s.initialH)).toDouble() * cellH;

        if ((s.initialW * cellW - deltaX) < minW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - minW),
            vPos.dy,
          );
          vSize = Size(minW, vSize.height);
        } else if ((s.initialW * cellW - deltaX) > maxW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - maxW),
            vPos.dy,
          );
          vSize = Size(maxW, vSize.height);
        } else {
          vPos = Offset(
            (s.initialX * cellW + deltaX).clamp(0, double.infinity),
            vPos.dy,
          );
          vSize = Size(s.initialW * cellW - deltaX, vSize.height);
        }

        if ((s.initialH * cellH - deltaY) < minH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - minH),
          );
          vSize = Size(vSize.width, minH);
        } else if ((s.initialH * cellH - deltaY) > maxH) {
          vPos = Offset(
            vPos.dx,
            s.initialY * cellH + (s.initialH * cellH - maxH),
          );
          vSize = Size(vSize.width, maxH);
        } else {
          vPos = Offset(
            vPos.dx,
            (s.initialY * cellH + deltaY).clamp(0, double.infinity),
          );
          vSize = Size(vSize.width, s.initialH * cellH - deltaY);
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          math.max(
            0,
            s.initialX +
                s.initialW -
                (s.preview.maxW ?? s.initialX + s.initialW),
          ),
          s.initialX + s.initialW - s.preview.minW,
        );
        final int snappedY = (vPos.dy / cellH).round().clamp(
          math.max(
            0,
            s.initialY +
                s.initialH -
                (s.preview.maxH ?? s.initialY + s.initialH),
          ),
          s.initialY + s.initialH - s.preview.minH,
        );
        p = p.copyWith(
          x: snappedX,
          w: s.initialX + s.initialW - snappedX,
          y: snappedY,
          h: s.initialY + s.initialH - snappedY,
        );
        break;
      case ZeusHandle.bottomLeft:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;

        final double minW = s.preview.minW * cellW;
        final double maxW =
            (s.preview.maxW ?? (s.initialX + s.initialW)).toDouble() * cellW;

        if ((s.initialW * cellW - deltaX) < minW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - minW),
            vPos.dy,
          );
          vSize = Size(
            minW,
            (s.initialH * cellH + deltaY).clamp(
              s.preview.minH * cellH,
              (s.preview.maxH ?? rows).toDouble() * cellH,
            ),
          );
        } else if ((s.initialW * cellW - deltaX) > maxW) {
          vPos = Offset(
            s.initialX * cellW + (s.initialW * cellW - maxW),
            vPos.dy,
          );
          vSize = Size(
            maxW,
            (s.initialH * cellH + deltaY).clamp(
              s.preview.minH * cellH,
              (s.preview.maxH ?? rows).toDouble() * cellH,
            ),
          );
        } else {
          vPos = Offset(
            (s.initialX * cellW + deltaX).clamp(0, double.infinity),
            vPos.dy,
          );
          vSize = Size(
            s.initialW * cellW - deltaX,
            (s.initialH * cellH + deltaY).clamp(
              s.preview.minH * cellH,
              (s.preview.maxH ?? rows).toDouble() * cellH,
            ),
          );
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          math.max(
            0,
            s.initialX +
                s.initialW -
                (s.preview.maxW ?? s.initialX + s.initialW),
          ),
          s.initialX + s.initialW - s.preview.minW,
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          (s.preview.maxH ?? (rows - s.initialY)).clamp(0, rows - s.initialY),
        );
        p = p.copyWith(
          x: snappedX,
          w: s.initialX + s.initialW - snappedX,
          h: snappedH,
        );
        break;
    }

    bool packingValid = s.isValid;
    if (p.x != s.preview.x ||
        p.y != s.preview.y ||
        p.w != s.preview.w ||
        p.h != s.preview.h) {
      if (widget.autoPack) {
        packingValid = _calculatePacking(p, cols, rows);
      }
    }

    _activeSession.value = s.copyWith(
      preview: p,
      isOverGrid: overGrid,
      isOverArsenal: isOverArsenal,
      isValid: packingValid && !_collision(p),
      visualPosition: vPos,
      visualSize: vSize,
    );
  }

  void _endSession() {
    final s = _activeSession.value;
    if (s == null) return;

    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final localMouse = _lastMousePosition;

    bool hasMovedSignificantly = false;
    if (localMouse != null) {
      // Check if mouse moved more than a few pixels from the start
      // Note: anchor might be offset for 'move' handle, but for resize it is the start point.
      // For simplicity, we can just check if grid coordinates changed.
      hasMovedSignificantly =
          s.preview.x != s.initialX ||
          s.preview.y != s.initialY ||
          s.preview.w != s.initialW ||
          s.preview.h != s.initialH;
    }

    if (!s.isFromDrawer &&
        s.isOverArsenal &&
        hasMovedSignificantly &&
        s.handle == ZeusHandle.move) {
      widget.onModuleRemove(s.id);
    } else if (s.isValid) {
      // Prioritize snapping to ghost location (clamped position)
      if (widget.autoPack && _packedModules.value != null) {
        // Find modules that moved during auto-packing and update them
        for (var m in _packedModules.value!) {
          final original = widget.modules.firstWhere((o) => o.id == m.id);
          if (m.x != original.x ||
              m.y != original.y ||
              m.w != original.w ||
              m.h != original.h) {
            widget.onModuleUpdate(m);
          }
        }
      }
      widget.onModuleUpdate(s.preview);
    } else if (!s.isValid && s.isOverGrid) {
      widget.onCollisionDetected?.call(s.preview);
    }

    _activeSession.value = null;
    _activeSessionId.value = null;
    _packedModules.value = null;

    if (rb != null && localMouse != null) {
      final module = s.preview;

      final double cellW = widget.columns != null ? rb.size.width / widget.columns! : widget.cellSide;
      final double cellH = widget.columns != null ? cellW : widget.cellSide;

      final left = module.x * cellW;
      final top = module.y * cellH;
      final right = left + module.w * cellW;
      final bottom = top + module.h * cellH;

      if (localMouse.dx >= left &&
          localMouse.dx <= right &&
          localMouse.dy >= top &&
          localMouse.dy <= bottom) {
        _focusedModuleId.value = s.id;
      }
      }
      _lastMousePosition = null;
  }

  bool _collision(ZeusModule t) {
    if (widget.autoPack) return false; // In autoPack mode, we clear space.
    for (var o in widget.modules) {
      if (o.id == t.id) continue;
      if (_checkCollisionBetween(t, o)) {
        return true;
      }
    }
    return false;
  }

  bool _checkCollisionBetween(ZeusModule a, ZeusModule b) {
    return a.x < (b.x + b.w) &&
        (a.x + a.w) > b.x &&
        a.y < (b.y + b.h) &&
        (a.y + a.h) > b.y;
  }

  bool _calculatePacking(ZeusModule active, int maxCols, int maxRows) {
    if (!widget.autoPack) return true;

    final others = widget.modules.where((m) => m.id != active.id).toList();
    List<ZeusModule> packed = others.map((e) => e.copy()).toList();

    bool changed = true;
    int iterations = 0;
    while (changed && iterations < 100) {
      changed = false;
      iterations++;

      for (int i = 0; i < packed.length; i++) {
        var m = packed[i];
        if (_checkCollisionBetween(active, m)) {
          ZeusModule newM;
          switch (widget.packDirection) {
            case PackDirection.down:
              final newY = active.y + active.h;
              if (newY + m.h > maxRows) return false;
              newM = m.copyWith(y: newY);
              break;
            case PackDirection.up:
              final newY = active.y - m.h;
              if (newY < 0) return false;
              newM = m.copyWith(y: newY);
              break;
            case PackDirection.right:
              final newX = active.x + active.w;
              if (newX + m.w > maxCols) return false;
              newM = m.copyWith(x: newX);
              break;
            case PackDirection.left:
              final newX = active.x - m.w;
              if (newX < 0) return false;
              newM = m.copyWith(x: newX);
              break;
          }
          packed[i] = newM;
          changed = true;
        }

        for (int j = 0; j < packed.length; j++) {
          if (i == j) continue;
          if (_checkCollisionBetween(packed[i], packed[j])) {
            ZeusModule m1 = packed[i];
            ZeusModule m2 = packed[j];

            switch (widget.packDirection) {
              case PackDirection.down:
                if (m1.y >= m2.y) {
                  final newY = m2.y + m2.h;
                  if (newY + m1.h > maxRows) return false;
                  packed[i] = m1.copyWith(y: newY);
                } else {
                  final newY = m1.y + m1.h;
                  if (newY + m2.h > maxRows) return false;
                  packed[j] = m2.copyWith(y: newY);
                }
                break;
              case PackDirection.up:
                if (m1.y <= m2.y) {
                  final newY = m2.y - m1.h;
                  if (newY < 0) return false;
                  packed[i] = m1.copyWith(y: newY);
                } else {
                  final newY = m1.y - m2.h;
                  if (newY < 0) return false;
                  packed[j] = m2.copyWith(y: newY);
                }
                break;
              case PackDirection.right:
                if (m1.x >= m2.x) {
                  final newX = m2.x + m2.w;
                  if (newX + m1.w > maxCols) return false;
                  packed[i] = m1.copyWith(x: newX);
                } else {
                  final newX = m1.x + m1.w;
                  if (newX + m2.w > maxCols) return false;
                  packed[j] = m2.copyWith(x: newX);
                }
                break;
              case PackDirection.left:
                if (m1.x <= m2.x) {
                  final newX = m2.x - m1.w;
                  if (newX < 0) return false;
                  packed[i] = m1.copyWith(x: newX);
                } else {
                  final newX = m1.x - m2.w;
                  if (newX < 0) return false;
                  packed[j] = m2.copyWith(x: newX);
                }
                break;
            }
            changed = true;
          }
        }
      }
    }
    _packedModules.value = packed;
    return true;
  }

  Widget _buildArsenalDrawer(bool visible, double cellW, double cellH) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: visible ? 0 : -widget.menuStyle.width,
      top: 0,
      bottom: 0,
      width: widget.menuStyle.width,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: widget.menuStyle.backgroundColor,
            border: const Border(left: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Text(
                  widget.menuStyle.title,
                  style: widget.menuStyle.titleStyle,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<ZeusSession?>(
                  valueListenable: _activeSession,
                  builder: (context, session, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: session != null
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      itemCount: widget.unplacedModules.length,
                      itemBuilder: (context, i) {
                        final m = widget.unplacedModules[i];
                        final isDragged =
                            session?.isFromDrawer == true &&
                            session?.id == m.id;

                        if (isDragged) {
                          return const SizedBox.shrink();
                        }

                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) => _startSession(m, e, true),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              border: Border.all(
                                color: Colors.white.withAlpha(26),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.id.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZeusModuleWidget extends StatelessWidget {
  final ZeusModule module;
  final ZeusSession? session;
  final bool isEditing;
  final bool isFocused;
  final double cellW;
  final double cellH;
  final ModuleStyle moduleStyle;
  final Widget content;
  final Function(ZeusModule, PointerDownEvent, bool, {ZeusHandle handle})
  onStartSession;
  final VoidCallback onRemove;
  final Function(String?) onFocusChange;

  const ZeusModuleWidget({
    super.key,
    required this.module,
    required this.session,
    required this.isEditing,
    required this.isFocused,
    required this.cellW,
    required this.cellH,
    required this.moduleStyle,
    required this.content,
    required this.onStartSession,
    required this.onRemove,
    required this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    final m = module;
    final isActive = session?.id == m.id;
    final isValid = isActive ? session!.isValid : true;

    final x = isActive ? session!.visualPosition.dx : m.x * cellW;
    final y = isActive ? session!.visualPosition.dy : m.y * cellH;
    final double physicalW = isActive
        ? session!.visualSize.width
        : (m.w * cellW);
    final double physicalH = isActive
        ? session!.visualSize.height
        : (m.h * cellH);

    final hLen =
        (physicalW < (_kHandleLength * 3) || physicalH < (_kHandleLength * 3))
        ? (physicalW < physicalH ? physicalW / 3 : physicalH / 3)
        : _kHandleLength;
    final hitS =
        (physicalW < (_kHitAreaSize * 2) || physicalH < (_kHitAreaSize * 2))
        ? (physicalW < physicalH ? physicalW / 2 : physicalH / 2)
        : _kHitAreaSize;

    return AnimatedPositioned(
      key: ValueKey('module_${m.id}'),
      duration: (session != null)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: x,
      top: y,
      width: physicalW,
      height: physicalH,
      child: RepaintBoundary(
        child: MouseRegion(
          onHover: (e) {
            if (!isEditing || isActive) return;
            final lx = e.localPosition.dx;
            final ly = e.localPosition.dy;
            if (lx >= 0 && lx <= physicalW && ly >= 0 && ly <= physicalH) {
              onFocusChange(m.id);
            } else {
              onFocusChange(null);
            }
          },
          onExit: (_) {
            if (isEditing && !isActive) {
              onFocusChange(null);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) =>
                      isEditing ? onStartSession(m, e, false) : null,
                  child: _ModuleCard(
                    module: m,
                    isActive: isActive,
                    isFocused: isFocused,
                    isValid: isValid,
                    moduleStyle: moduleStyle,
                    content: content,
                  ),
                ),
              ),
              if (isEditing && (isFocused || isActive)) ...[
                _ResizeHandle(
                  handle: ZeusHandle.topLeft,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: _kHandleInset,
                  top: _kHandleInset,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.topRight,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: physicalW - _kHandleInset - hLen,
                  top: _kHandleInset,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.bottomRight,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: physicalW - _kHandleInset - hLen,
                  top: physicalH - _kHandleInset - _kHandleThickness,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.bottomLeft,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: _kHandleInset,
                  top: physicalH - _kHandleInset - _kHandleThickness,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.top,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: physicalW / 2 - (hLen / 2),
                  top: _kHandleInset,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.bottom,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: physicalW / 2 - (hLen / 2),
                  top: physicalH - _kHandleInset - _kHandleThickness,
                  width: hLen,
                  height: _kHandleThickness,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.left,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: _kHandleInset,
                  top: physicalH / 2 - (hLen / 2),
                  width: _kHandleThickness,
                  height: hLen,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                _ResizeHandle(
                  handle: ZeusHandle.right,
                  onStartSession: (e, h) =>
                      onStartSession(m, e, false, handle: h),
                  builder: moduleStyle.resizeHandleBuilder,
                  left: physicalW - _kHandleInset - _kHandleThickness,
                  top: physicalH / 2 - (hLen / 2),
                  width: _kHandleThickness,
                  height: hLen,
                  hitWidth: hitS,
                  hitHeight: hitS,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ZeusModule module;
  final bool isActive;
  final bool isFocused;
  final bool isValid;
  final ModuleStyle moduleStyle;
  final Widget content;

  const _ModuleCard({
    required this.module,
    required this.isActive,
    required this.isFocused,
    required this.isValid,
    required this.moduleStyle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final border = (isFocused || isActive)
        ? (isValid
              ? moduleStyle.activeBorderColor
              : moduleStyle.warningBorderColor)
        : Colors.white.withAlpha(26);

    final Color effectiveBorder = (isFocused || isActive)
        ? border
        : Colors.white.withAlpha(26);

    final bgColor = isActive
        ? Color.alphaBlend(border.withAlpha(50), moduleStyle.color)
        : moduleStyle.color;

    return Opacity(
      opacity: isActive ? moduleStyle.activeOpacity : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: effectiveBorder,
            width: (isFocused || isActive) ? 2.0 : 1.0,
          ),
          borderRadius: moduleStyle.borderRadius,
          boxShadow: isActive
              ? moduleStyle.activeShadow
              : moduleStyle.baseShadow,
        ),
        child: ClipRRect(
          borderRadius: moduleStyle.borderRadius,
          child: content,
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final ZeusHandle handle;
  final Function(PointerDownEvent, ZeusHandle) onStartSession;
  final Widget Function(ZeusHandle direction)? builder;
  final double? left, top, width, height, hitWidth, hitHeight;

  const _ResizeHandle({
    required this.handle,
    required this.onStartSession,
    this.builder,
    this.left,
    this.top,
    this.width,
    this.height,
    this.hitWidth,
    this.hitHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (builder != null) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => onStartSession(e, handle),
          child: builder!(handle),
        ),
      );
    }

    final hWidth = hitWidth ?? _kHitAreaSize;
    final hHeight = hitHeight ?? _kHitAreaSize;

    final hLeft = left != null ? left! - (hWidth - (width ?? 0)) / 2 : 0.0;
    final hTop = top != null ? top! - (hHeight - (height ?? 0)) / 2 : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (handle == ZeusHandle.topLeft) ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left,
            top: top,
            width: height,
            height: width,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.topRight) ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left != null ? left! + (width! - height!) : null,
            top: top,
            width: height,
            height: width,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.bottomRight) ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left != null ? left! + (width! - height!) : null,
            top: top != null ? top! - (width! - height!) : null,
            width: height,
            height: width,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.bottomLeft) ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left,
            top: top != null ? top! - (width! - height!) : null,
            width: height,
            height: width,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
        Positioned(
          left: hLeft,
          top: hTop,
          width: hWidth,
          height: hHeight,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => onStartSession(e, handle),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class ZeusGridBackground extends StatelessWidget {
  final GridStyle style;
  final double cellW;
  final double cellH;
  final int rows;
  final int cols;

  const ZeusGridBackground({
    super.key,
    required this.style,
    required this.cellW,
    required this.cellH,
    required this.rows,
    required this.cols,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: GridPainter(
          style: style,
          cellW: cellW,
          cellH: cellH,
          rows: rows,
          cols: cols,
        ),
      ),
    );
  }
}

class _ModuleWrapper extends StatelessWidget {
  final ZeusModule initialModule;
  final ValueNotifier<String?> activeSessionId;
  final ValueNotifier<ZeusSession?> activeSession;
  final ValueNotifier<List<ZeusModule>?> packedModules;
  final bool isEditing;
  final bool isFocused;
  final double cellW;
  final double cellH;
  final ModuleStyle moduleStyle;
  final Widget content;
  final Function(ZeusModule, PointerDownEvent, bool, {ZeusHandle handle})
  onStartSession;
  final VoidCallback onRemove;
  final Function(String?) onFocusChange;

  const _ModuleWrapper({
    super.key,
    required this.initialModule,
    required this.activeSessionId,
    required this.activeSession,
    required this.packedModules,
    required this.isEditing,
    required this.isFocused,
    required this.cellW,
    required this.cellH,
    required this.moduleStyle,
    required this.content,
    required this.onStartSession,
    required this.onRemove,
    required this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: activeSessionId,
      builder: (context, activeId, _) {
        final bool isCurrentlyActive = activeId == initialModule.id;

        if (isCurrentlyActive) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<List<ZeusModule>?>(
          valueListenable: packedModules,
          builder: (context, packed, _) {
            ZeusModule displayModule = initialModule;
            if (packed != null) {
              final idx = packed.indexWhere((m) => m.id == initialModule.id);
              if (idx != -1) {
                displayModule = packed[idx];
              }
            }

            return ZeusModuleWidget(
              key: ValueKey('module_${displayModule.id}'),
              module: displayModule,
              session: null,
              isEditing: isEditing,
              isFocused: isFocused,
              cellW: cellW,
              cellH: cellH,
              moduleStyle: moduleStyle,
              content: content,
              onStartSession: onStartSession,
              onRemove: onRemove,
              onFocusChange: onFocusChange,
            );
          },
        );
      },
    );
  }
}
