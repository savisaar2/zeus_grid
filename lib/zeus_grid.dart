import 'package:flutter/material.dart';
import 'src/models.dart';
import 'src/grid_painter.dart';

export 'src/models.dart';

class ZeusGrid extends StatefulWidget {
  final List<ZeusModule> modules, unplacedModules;
  final bool isEditing;
  final Widget Function(String id) onGenerateContent;
  final Function(ZeusModule) onModuleUpdate;
  final Function(String) onModuleRemove;
  final GridStyle gridStyle;
  final ModuleStyle moduleStyle;
  final ZeusMenuStyle menuStyle;
  final double cellSide;

  const ZeusGrid({
    super.key,
    required this.modules,
    required this.unplacedModules,
    required this.isEditing,
    required this.onGenerateContent,
    required this.onModuleUpdate,
    required this.onModuleRemove,
    this.gridStyle = const GridStyle(),
    this.moduleStyle = const ModuleStyle(),
    this.menuStyle = const ZeusMenuStyle(),
    this.cellSide = 10.0,
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
  String? _focusedModuleId;
  Offset? _lastMousePosition;
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (_lastSize != null && _lastSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pushModulesIntoBounds(size);
          });
        }
        _lastSize = size;

        final cellW = widget.cellSide;
        final cellH = widget.cellSide;
        
        final cols = (constraints.maxWidth / widget.cellSide).ceil();
        final rows = (constraints.maxHeight / widget.cellSide).ceil();

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _updateSession,
          onPointerUp: (_) => _endSession(),
          onPointerCancel: (_) {
            _activeSession.value = null;
            _activeSessionId.value = null;
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

  void _pushModulesIntoBounds(Size size) {
    final cols = (size.width / widget.cellSide).floor();
    final rows = (size.height / widget.cellSide).floor();

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
          // Layer 1: Static Grid & Background Modules
          ValueListenableBuilder<String?>(
            valueListenable: _activeSessionId,
            builder: (context, activeId, _) {
              final List<ZeusModule> staticModules =
                  widget.modules.where((m) => m.id != activeId).toList();

              // Sort to ensure focused module is on top of other static modules
              staticModules.sort(
                (a, b) => (a.id == _focusedModuleId) ? 1 : -1,
              );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.isEditing)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          style: widget.gridStyle,
                          cellW: cellW,
                          cellH: cellH,
                          rows: rows,
                          cols: cols,
                        ),
                      ),
                    ),
                  ...staticModules.map((m) =>
                      _buildModuleWrapper(m, null, cellW, cellH, cols, rows)),
                ],
              );
            },
          ),
          // Layer 2: Dynamic Active Module
          ValueListenableBuilder<ZeusSession?>(
            valueListenable: _activeSession,
            builder: (context, session, _) {
              if (session == null || !session.isOverGrid) {
                return const SizedBox.shrink();
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The "Ghost" Preview (snapped)
                  _buildGhost(session.preview, session.isValid, cellW, cellH),
                  // The smooth Active Module
                  _buildModuleWrapper(
                      session.preview, session, cellW, cellH, cols, rows),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGhost(ZeusModule m, bool isValid, double cellW, double cellH) {
    return Positioned(
      left: m.x * cellW,
      top: m.y * cellH,
      width: m.w * cellW,
      height: m.h * cellH,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isValid ? Colors.cyanAccent.withAlpha(100) : Colors.redAccent.withAlpha(100),
            width: 2,
          ),
          borderRadius: widget.moduleStyle.borderRadius,
        ),
      ),
    );
  }

  Widget _buildModuleWrapper(
    ZeusModule m,
    ZeusSession? session,
    double cellW,
    double cellH,
    int gridCols,
    int gridRows,
  ) {
    final isActive = session?.id == m.id;
    final isFocused = widget.isEditing && _focusedModuleId == m.id;
    final isValid = isActive ? session!.isValid : true;

    final x = isActive ? session!.visualPosition.dx : m.x * cellW;
    final y = isActive ? session!.visualPosition.dy : m.y * cellH;
    final double physicalW = isActive ? session!.visualSize.width : (m.w * cellW);
    final double physicalH = isActive ? session!.visualSize.height : (m.h * cellH);

    final hLen = (physicalW < (_kHandleLength * 3) || physicalH < (_kHandleLength * 3))
        ? (physicalW < physicalH ? physicalW / 3 : physicalH / 3)
        : _kHandleLength;
    final hitS = (physicalW < (_kHitAreaSize * 2) || physicalH < (_kHitAreaSize * 2))
        ? (physicalW < physicalH ? physicalW / 2 : physicalH / 2)
        : _kHitAreaSize;

    return AnimatedPositioned(
      duration: (session != null) ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: x,
      top: y,
      width: physicalW,
      height: physicalH,
      child: MouseRegion(
        onHover: (e) {
          if (!widget.isEditing || isActive) return;
          final lx = e.localPosition.dx;
          final ly = e.localPosition.dy;
          if (lx >= 0 &&
              lx <= physicalW &&
              ly >= 0 &&
              ly <= physicalH) {
            if (_focusedModuleId != m.id) {
              setState(() => _focusedModuleId = m.id);
            }
          } else {
            if (_focusedModuleId == m.id) {
              setState(() => _focusedModuleId = null);
            }
          }
        },
        onExit: (_) {
          if (widget.isEditing && !isActive && _focusedModuleId == m.id) {
            setState(() => _focusedModuleId = null);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Move Listener wraps only the Card
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) =>
                    widget.isEditing ? _startSession(m, e, false) : null,
                child: _buildCard(
                  m,
                  isActive,
                  isFocused,
                  isValid,
                  m.x,
                  m.y,
                  m.w,
                  m.h,
                ),
              ),
            ),
            if (widget.isEditing && (isFocused || isActive)) ...[
              _buildResizeHandle(
                m,
                ZeusHandle.topLeft,
                left: _kHandleInset,
                top: _kHandleInset,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.topRight,
                left: physicalW - _kHandleInset - hLen,
                top: _kHandleInset,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottomRight,
                left: physicalW - _kHandleInset - hLen,
                top: physicalH - _kHandleInset - _kHandleThickness,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottomLeft,
                left: _kHandleInset,
                top: physicalH - _kHandleInset - _kHandleThickness,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.top,
                left: physicalW / 2 - (hLen / 2),
                top: _kHandleInset,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottom,
                left: physicalW / 2 - (hLen / 2),
                top: physicalH - _kHandleInset - _kHandleThickness,
                width: hLen,
                height: _kHandleThickness,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.left,
                left: _kHandleInset,
                top: physicalH / 2 - (hLen / 2),
                width: _kHandleThickness,
                height: hLen,
                hitWidth: hitS,
                hitHeight: hitS,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.right,
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
                  onTap: () => widget.onModuleRemove(m.id),
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
    );
  }

  Widget _buildResizeHandle(
    ZeusModule m,
    ZeusHandle handle, {
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
    double? hitLeft,
    double? hitTop,
    double? hitWidth,
    double? hitHeight,
  }) {
    final hWidth = hitWidth ?? _kHitAreaSize;
    final hHeight = hitHeight ?? _kHitAreaSize;

    // Center hit area over visual bars
    final hLeft = hitLeft ?? (left != null ? left - (hWidth - (width ?? 0)) / 2 : (right != null ? right - hWidth : 0));
    final hTop = hitTop ?? (top != null ? top - (hHeight - (height ?? 0)) / 2 : (bottom != null ? bottom - hHeight : 0));

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
            left: left != null ? left + (width! - height!) : null,
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
            left: left != null ? left + (width! - height!) : null,
            top: top != null ? top - (width! - height!) : null,
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
            top: top != null ? top - (width! - height!) : null,
            width: height,
            height: width,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.top || handle == ZeusHandle.bottom) ...[
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
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
        // Hit area moved to last position in Stack to be on top of visual bars
        Positioned(
          left: hLeft,
          top: hTop,
          width: hWidth,
          height: hHeight,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _startSession(m, e, false, handle: handle),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    ZeusModule m,
    bool isActive,
    bool isFocused,
    bool isValid,
    int x,
    int y,
    int w,
    int h,
  ) {
    final border = (isFocused || isActive)
        ? (isValid
              ? widget.moduleStyle.activeBorderColor
              : widget.moduleStyle.warningBorderColor)
        : (widget.isEditing ? Colors.white.withAlpha(26) : Colors.transparent);

    final bgColor = isActive
        ? Color.alphaBlend(
            border.withAlpha(50),
            widget.moduleStyle.color,
          )
        : widget.moduleStyle.color;

    return Opacity(
      opacity: isActive ? widget.moduleStyle.activeOpacity : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: border,
            width: (isFocused || isActive) ? 2.0 : 1.0,
          ),
          borderRadius: widget.moduleStyle.borderRadius,
        ),
        child: ClipRRect(
          borderRadius: widget.moduleStyle.borderRadius,
          child: widget.onGenerateContent(m.id),
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

    final cellW = widget.cellSide;
    final cellH = widget.cellSide;
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
    _focusedModuleId = m.id;
    _lastMousePosition = rb.globalToLocal(e.position);
  }

  void _updateSession(PointerMoveEvent e) {
    final s = _activeSession.value;
    if (s == null) return;
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final cellW = widget.cellSide;
    final cellH = widget.cellSide;
    
    final cols = (rb.size.width / widget.cellSide).ceil();
    final rows = (rb.size.height / widget.cellSide).ceil();

    final local = rb.globalToLocal(e.position);
    _lastMousePosition = local;

    bool overGrid =
        local.dx >= -40 &&
        local.dx <= (rb.size.width + 40) &&
        local.dy >= -40 &&
        local.dy <= (rb.size.height + 40);

    if (widget.isEditing) {
      // Must be significantly over the arsenal drawer to trigger removal (e.g. 100px in)
      if (local.dx >= (rb.size.width - widget.menuStyle.width + 100)) {
        overGrid = false;
      }
    }

    ZeusModule p = s.preview;
    final int gridX = (local.dx / cellW).floor();
    final int gridY = (local.dy / cellH).floor();

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
          (s.initialW * cellW + deltaX).clamp(s.preview.minW * cellW, double.infinity),
          vSize.height,
        );
        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          cols - p.x,
        );
        p = p.copyWith(w: snappedW);
        break;
      case ZeusHandle.left:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double rawX = s.initialX * cellW + deltaX;
        final double rawW = s.initialW * cellW - deltaX;
        
        final double minW = s.preview.minW * cellW;
        if (rawW < minW) {
          vPos = Offset(s.initialX * cellW + (s.initialW * cellW - minW), vPos.dy);
          vSize = Size(minW, vSize.height);
        } else {
          vPos = Offset(rawX.clamp(0, double.infinity), vPos.dy);
          vSize = Size(rawW, vSize.height);
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        );
        p = p.copyWith(x: snappedX, w: s.initialX + s.initialW - snappedX);
        break;
      case ZeusHandle.bottom:
        final double deltaY = local.dy - s.initialGridY * cellH;
        vSize = Size(
          vSize.width,
          (s.initialH * cellH + deltaY).clamp(s.preview.minH * cellH, double.infinity),
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          rows - s.initialY,
        );
        p = p.copyWith(h: snappedH);
        break;
      case ZeusHandle.top:
        final double deltaY = local.dy - s.initialGridY * cellH;
        final double rawY = s.initialY * cellH + deltaY;
        final double rawH = s.initialH * cellH - deltaY;

        final double minH = s.preview.minH * cellH;
        if (rawH < minH) {
          vPos = Offset(vPos.dx, s.initialY * cellH + (s.initialH * cellH - minH));
          vSize = Size(vSize.width, minH);
        } else {
          vPos = Offset(vPos.dx, rawY.clamp(0, double.infinity));
          vSize = Size(vSize.width, rawH);
        }

        final int snappedY = (vPos.dy / cellH).round().clamp(
          0,
          s.initialY + s.initialH - s.preview.minH,
        );
        p = p.copyWith(
          y: snappedY,
          h: s.initialY + s.initialH - snappedY,
        );
        break;
      case ZeusHandle.bottomRight:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;
        vSize = Size(
          (s.initialW * cellW + deltaX).clamp(s.preview.minW * cellW, double.infinity),
          (s.initialH * cellH + deltaY).clamp(s.preview.minH * cellH, double.infinity),
        );
        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          cols - s.initialX,
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          rows - s.initialY,
        );
        p = p.copyWith(w: snappedW, h: snappedH);
        break;
      case ZeusHandle.topRight:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;
        
        vSize = Size(
          (s.initialW * cellW + deltaX).clamp(s.preview.minW * cellW, double.infinity),
          (s.initialH * cellH - deltaY).clamp(s.preview.minH * cellH, double.infinity),
        );
        
        final double minH = s.preview.minH * cellH;
        if ((s.initialH * cellH - deltaY) < minH) {
          vPos = Offset(vPos.dx, s.initialY * cellH + (s.initialH * cellH - minH));
        } else {
          vPos = Offset(vPos.dx, (s.initialY * cellH + deltaY).clamp(0, double.infinity));
        }

        final int snappedW = (vSize.width / cellW).round().clamp(
          s.preview.minW,
          cols - s.initialX,
        );
        final int snappedY = (vPos.dy / cellH).round().clamp(
          0,
          s.initialY + s.initialH - s.preview.minH,
        );
        p = p.copyWith(w: snappedW, y: snappedY, h: s.initialY + s.initialH - snappedY);
        break;
      case ZeusHandle.topLeft:
        final double deltaX = local.dx - s.initialGridX * cellW;
        final double deltaY = local.dy - s.initialGridY * cellH;

        final double minW = s.preview.minW * cellW;
        final double minH = s.preview.minH * cellH;

        if ((s.initialW * cellW - deltaX) < minW) {
          vPos = Offset(s.initialX * cellW + (s.initialW * cellW - minW), vPos.dy);
          vSize = Size(minW, vSize.height);
        } else {
          vPos = Offset((s.initialX * cellW + deltaX).clamp(0, double.infinity), vPos.dy);
          vSize = Size(s.initialW * cellW - deltaX, vSize.height);
        }

        if ((s.initialH * cellH - deltaY) < minH) {
          vPos = Offset(vPos.dx, s.initialY * cellH + (s.initialH * cellH - minH));
          vSize = Size(vSize.width, minH);
        } else {
          vPos = Offset(vPos.dx, (s.initialY * cellH + deltaY).clamp(0, double.infinity));
          vSize = Size(vSize.width, s.initialH * cellH - deltaY);
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        );
        final int snappedY = (vPos.dy / cellH).round().clamp(
          0,
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
        if ((s.initialW * cellW - deltaX) < minW) {
          vPos = Offset(s.initialX * cellW + (s.initialW * cellW - minW), vPos.dy);
          vSize = Size(minW, (s.initialH * cellH + deltaY).clamp(s.preview.minH * cellH, double.infinity));
        } else {
          vPos = Offset((s.initialX * cellW + deltaX).clamp(0, double.infinity), vPos.dy);
          vSize = Size(s.initialW * cellW - deltaX, (s.initialH * cellH + deltaY).clamp(s.preview.minH * cellH, double.infinity));
        }

        final int snappedX = (vPos.dx / cellW).round().clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        );
        final int snappedH = (vSize.height / cellH).round().clamp(
          s.preview.minH,
          rows - s.initialY,
        );
        p = p.copyWith(x: snappedX, w: s.initialX + s.initialW - snappedX, h: snappedH);
        break;
    }

    _activeSession.value = s.copyWith(
      preview: p,
      isOverGrid: overGrid,
      isValid: !_collision(p),
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
      hasMovedSignificantly = s.preview.x != s.initialX ||
          s.preview.y != s.initialY ||
          s.preview.w != s.initialW ||
          s.preview.h != s.initialH;
    }

    if (!s.isFromDrawer && !s.isOverGrid && hasMovedSignificantly) {
      widget.onModuleRemove(s.id);
    } else if (s.isValid && s.isOverGrid) {
      widget.onModuleUpdate(s.preview);
    }

    _activeSession.value = null;
    _activeSessionId.value = null;

    if (rb != null && localMouse != null) {
      final module = s.preview;
      
      final cellW = widget.cellSide;
      final cellH = widget.cellSide;

      final left = module.x * cellW;
      final top = module.y * cellH;
      final right = left + module.w * cellW;
      final bottom = top + module.h * cellH;

      if (localMouse.dx >= left &&
          localMouse.dx <= right &&
          localMouse.dy >= top &&
          localMouse.dy <= bottom) {
        _focusedModuleId = s.id;
      }
    }
    _lastMousePosition = null;
  }

  bool _collision(ZeusModule t) {
    for (var o in widget.modules) {
      if (o.id == t.id) continue;
      if (t.x < (o.x + o.w) &&
          (t.x + t.w) > o.x &&
          t.y < (o.y + o.h) &&
          (t.y + t.h) > o.y) {
        return true;
      }
    }
    return false;
  }

  Widget _buildArsenalDrawer(bool visible, double cellW, double cellH) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: visible ? 0 : -widget.menuStyle.width,
      top: 0,
      bottom: 0,
      width: widget.menuStyle.width,
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
                      final isDragged = session?.isFromDrawer == true && session?.id == m.id;
                      
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
    );
  }
}
