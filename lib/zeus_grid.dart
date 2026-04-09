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
  final int columns, rows;
  final GridStyle gridStyle;
  final ModuleStyle moduleStyle;
  final ZeusMenuStyle menuStyle;

  const ZeusGrid({
    super.key,
    required this.modules,
    required this.unplacedModules,
    required this.isEditing,
    required this.onGenerateContent,
    required this.onModuleUpdate,
    required this.onModuleRemove,
    this.columns = 120,
    this.rows = 100,
    this.gridStyle = const GridStyle(),
    this.moduleStyle = const ModuleStyle(),
    this.menuStyle = const ZeusMenuStyle(),
  });

  @override
  State<ZeusGrid> createState() => _ZeusGridState();
}

const double _kPadding = 30.0;
const double _kHandleLength = 40.0;
const double _kHandleThickness = 5.0;
const double _kHitAreaSize = 80.0;
const double _kHandleInset = 20.0;

class _ZeusGridState extends State<ZeusGrid> {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<ZeusSession?> _activeSession = ValueNotifier(null);
  String? _focusedModuleId;
  Offset? _lastMousePosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.columns;
        final cellH = constraints.maxHeight / widget.rows;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _updateSession,
          onPointerUp: (_) => _endSession(),
          onPointerCancel: (_) => _activeSession.value = null,
          child: Stack(
            children: [
              Container(color: Colors.black),
              _buildVirtualGrid(cellW, cellH),
              _buildArsenalDrawer(widget.isEditing, cellW, cellH),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVirtualGrid(double cellW, double cellH) {
    return ValueListenableBuilder<ZeusSession?>(
      valueListenable: _activeSession,
      builder: (context, session, _) {
        final List<ZeusModule> list = List.from(widget.modules);

        if (session != null) {
          if (session.isFromDrawer && session.isOverGrid) {
            list.add(session.preview);
          } else if (!session.isFromDrawer) {
            final idx = list.indexWhere((m) => m.id == session.id);
            if (idx != -1) list[idx] = session.preview;
          }
        }

        list.sort(
          (a, b) => (a.id == session?.id || a.id == _focusedModuleId) ? 1 : -1,
        );

        return SizedBox.expand(
          child: Stack(
            key: _gridKey,
            clipBehavior: Clip.none,
            children: [
              if (widget.isEditing)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(
                      style: widget.gridStyle,
                      cellW: cellW,
                      cellH: cellH,
                      rows: widget.rows,
                      cols: widget.columns,
                    ),
                  ),
                ),
              ...list.map((m) => _buildModuleWrapper(m, session, cellW, cellH)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleWrapper(
    ZeusModule m,
    ZeusSession? session,
    double cellW,
    double cellH,
  ) {
    final isActive = session?.id == m.id;
    final isFocused = widget.isEditing && _focusedModuleId == m.id;
    final isValid = isActive ? session!.isValid : true;

    final x = isActive ? session!.preview.x : m.x;
    final y = isActive ? session!.preview.y : m.y;
    final w = isActive ? session!.preview.w : m.w;
    final h = isActive ? session!.preview.h : m.h;

    final double physicalW = (w * cellW).clamp(m.minW * cellW, double.infinity);
    final double physicalH = (h * cellH).clamp(m.minH * cellH, double.infinity);

    final double outerW = physicalW + (_kPadding * 2);
    final double outerH = physicalH + (_kPadding * 2);

    return Positioned(
      left: (x * cellW) - _kPadding,
      top: (y * cellH) - _kPadding,
      width: outerW,
      height: outerH,
      child: MouseRegion(
        onHover: (e) {
          if (!widget.isEditing || isActive) return;
          final lx = e.localPosition.dx;
          final ly = e.localPosition.dy;
          if (lx >= _kPadding &&
              lx <= _kPadding + physicalW &&
              ly >= _kPadding &&
              ly <= _kPadding + physicalH) {
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
            Positioned(
              left: _kPadding,
              top: _kPadding,
              child: SizedBox(
                width: physicalW,
                height: physicalH,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) =>
                      widget.isEditing ? _startSession(m, e, false) : null,
                  child: _buildCard(
                    m,
                    isActive,
                    isFocused,
                    isValid,
                    x,
                    y,
                    w,
                    h,
                  ),
                ),
              ),
            ),
            if (widget.isEditing && (isFocused || isActive)) ...[
              _buildResizeHandle(
                m,
                ZeusHandle.topLeft,
                hitLeft: _kPadding,
                hitTop: _kPadding,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + _kHandleInset,
                top: _kPadding + _kHandleInset,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.topRight,
                hitLeft: _kPadding + physicalW - _kHitAreaSize,
                hitTop: _kPadding,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + physicalW - _kHandleInset - _kHandleLength,
                top: _kPadding + _kHandleInset,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottomRight,
                hitLeft: _kPadding + physicalW - _kHitAreaSize,
                hitTop: _kPadding + physicalH - _kHitAreaSize,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + physicalW - _kHandleInset - _kHandleLength,
                top: _kPadding + physicalH - _kHandleInset - _kHandleThickness,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottomLeft,
                hitLeft: _kPadding,
                hitTop: _kPadding + physicalH - _kHitAreaSize,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + _kHandleInset,
                top: _kPadding + physicalH - _kHandleInset - _kHandleThickness,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.top,
                hitLeft: _kPadding + physicalW / 2 - (_kHitAreaSize / 2),
                hitTop: _kPadding,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + physicalW / 2 - (_kHandleLength / 2),
                top: _kPadding + _kHandleInset,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.bottom,
                hitLeft: _kPadding + physicalW / 2 - (_kHitAreaSize / 2),
                hitTop: _kPadding + physicalH - _kHitAreaSize,
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + physicalW / 2 - (_kHandleLength / 2),
                top: _kPadding + physicalH - _kHandleInset - _kHandleThickness,
                width: _kHandleLength,
                height: _kHandleThickness,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.left,
                hitLeft: _kPadding,
                hitTop: _kPadding + physicalH / 2 - (_kHitAreaSize / 2),
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + _kHandleInset,
                top: _kPadding + physicalH / 2 - (_kHandleLength / 2),
                width: _kHandleThickness,
                height: _kHandleLength,
              ),
              _buildResizeHandle(
                m,
                ZeusHandle.right,
                hitLeft: _kPadding + physicalW - _kHitAreaSize,
                hitTop: _kPadding + physicalH / 2 - (_kHitAreaSize / 2),
                hitWidth: _kHitAreaSize,
                hitHeight: _kHitAreaSize,
                left: _kPadding + physicalW - _kHandleInset - _kHandleThickness,
                top: _kPadding + physicalH / 2 - (_kHandleLength / 2),
                width: _kHandleThickness,
                height: _kHandleLength,
              ),
              Positioned(
                left: _kPadding + 8,
                top: _kPadding + 8,
                child: GestureDetector(
                  onTap: () => widget.onModuleRemove(m.id),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
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
    final hLeft = hitLeft ?? left ?? (right != null ? right! - 30 : 0);
    final hTop = hitTop ?? top ?? (bottom != null ? bottom! - 30 : 0);
    final hWidth = hitWidth ?? 30;
    final hHeight = hitHeight ?? 30;

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
        if (handle == ZeusHandle.topLeft) ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleLength,
            height: _kHandleThickness,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left,
            top: top,
            width: _kHandleThickness,
            height: _kHandleLength,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.topRight) ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleLength,
            height: _kHandleThickness,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left! + (_kHandleLength - _kHandleThickness),
            top: top,
            width: _kHandleThickness,
            height: _kHandleLength,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.bottomRight) ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleLength,
            height: _kHandleThickness,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left! + (_kHandleLength - _kHandleThickness),
            top: top! - (_kHandleLength - _kHandleThickness),
            width: _kHandleThickness,
            height: _kHandleLength,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.bottomLeft) ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleLength,
            height: _kHandleThickness,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: left,
            top: top! - (_kHandleLength - _kHandleThickness),
            width: _kHandleThickness,
            height: _kHandleLength,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else if (handle == ZeusHandle.top || handle == ZeusHandle.bottom) ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleLength,
            height: _kHandleThickness,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ] else ...[
          Positioned(
            left: left,
            top: top,
            width: _kHandleThickness,
            height: _kHandleLength,
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
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

    final cellW = rb.size.width / widget.columns;
    final cellH = rb.size.height / widget.rows;
    final local = rb.globalToLocal(e.position);

    final double visualW = (m.w * cellW).clamp(m.minW * cellW, double.infinity);
    final double visualH = (m.h * cellH).clamp(m.minH * cellH, double.infinity);

    Offset anchor;
    int initialGridX = m.x;
    int initialGridY = m.y;

    if (fromDrawer) {
      anchor = Offset(visualW / 2, visualH / 2);
    } else if (handle == ZeusHandle.move) {
      anchor = local - Offset(m.x * cellW, m.y * cellH);
    } else {
      anchor = local;
      initialGridX = (local.dx / cellW).round();
      initialGridY = (local.dy / cellH).round();
    }

    _activeSession.value = ZeusSession(
      id: m.id,
      preview: m.copy(),
      anchor: anchor,
      isFromDrawer: fromDrawer,
      handle: handle,
      initialGridX: initialGridX,
      initialGridY: initialGridY,
      initialW: m.w,
      initialH: m.h,
      initialX: m.x,
      initialY: m.y,
    );
    _focusedModuleId = m.id;
    _lastMousePosition = rb.globalToLocal(e.position);
  }

  void _updateSession(PointerMoveEvent e) {
    final s = _activeSession.value;
    if (s == null) return;
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final cellW = rb.size.width / widget.columns;
    final cellH = rb.size.height / widget.rows;
    final local = rb.globalToLocal(e.position);
    _lastMousePosition = local;

    bool overGrid =
        local.dx >= -20 &&
        local.dx <= (rb.size.width + 20) &&
        local.dy >= -20 &&
        local.dy <= (rb.size.height + 20);

    if (s.isFromDrawer && widget.isEditing) {
      overGrid = local.dx < (rb.size.width - widget.menuStyle.width + 50);
    }

    ZeusModule p = s.preview;
    final int gridX = (local.dx / cellW).round();
    final int gridY = (local.dy / cellH).round();

    switch (s.handle) {
      case ZeusHandle.move:
        final t = local - s.anchor;
        p = s.preview.copyWith(
          x: (t.dx / cellW).round().clamp(0, widget.columns - s.preview.w),
          y: (t.dy / cellH).round().clamp(0, widget.rows - s.preview.h),
        );
        break;
      case ZeusHandle.right:
        final int deltaX = gridX - s.initialGridX;
        final int newW = (s.initialW + deltaX).clamp(
          s.preview.minW,
          widget.columns - p.x,
        ).toInt();
        p = p.copyWith(w: newW);
        break;
      case ZeusHandle.left:
        final int deltaX = gridX - s.initialGridX;
        final int newX = (s.initialX + deltaX).clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        ).toInt();
        p = p.copyWith(x: newX, w: s.initialX + s.initialW - newX);
        break;
      case ZeusHandle.bottom:
        final int deltaY = gridY - s.initialGridY;
        final int newH = (s.initialH + deltaY).clamp(
          s.preview.minH,
          widget.rows - s.initialY,
        ).toInt();
        p = p.copyWith(h: newH);
        break;
      case ZeusHandle.top:
        final int deltaY = gridY - s.initialGridY;
        final int newY = (s.initialY + deltaY).clamp(
          0,
          s.initialY + s.initialH - s.preview.minH,
        ).toInt();
        p = p.copyWith(
          y: newY,
          h: s.initialY + s.initialH - newY,
        );
        break;
      case ZeusHandle.bottomRight:
        final int deltaX = gridX - s.initialGridX;
        final int deltaY = gridY - s.initialGridY;
        final int newW = (s.initialW + deltaX).clamp(
          s.preview.minW,
          widget.columns - s.initialX,
        ).toInt();
        final int newH = (s.initialH + deltaY).clamp(
          s.preview.minH,
          widget.rows - s.initialY,
        ).toInt();
        p = p.copyWith(w: newW, h: newH);
        break;
      case ZeusHandle.topRight:
        final int deltaX = gridX - s.initialGridX;
        final int deltaY = gridY - s.initialGridY;
        final int newW = (s.initialW + deltaX).clamp(
          s.preview.minW,
          widget.columns - s.initialX,
        ).toInt();
        final int newY = (s.initialY + deltaY).clamp(
          0,
          s.initialY + s.initialH - s.preview.minH,
        ).toInt();
        p = p.copyWith(w: newW, y: newY, h: s.initialY + s.initialH - newY);
        break;
      case ZeusHandle.topLeft:
        final int deltaX = gridX - s.initialGridX;
        final int deltaY = gridY - s.initialGridY;
        final int newX = (s.initialX + deltaX).clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        ).toInt();
        final int newY = (s.initialY + deltaY).clamp(
          0,
          s.initialY + s.initialH - s.preview.minH,
        ).toInt();
        p = p.copyWith(
          x: newX,
          w: s.initialX + s.initialW - newX,
          y: newY,
          h: s.initialY + s.initialH - newY,
        );
        break;
      case ZeusHandle.bottomLeft:
        final int deltaX = gridX - s.initialGridX;
        final int deltaY = gridY - s.initialGridY;
        final int newX = (s.initialX + deltaX).clamp(
          0,
          s.initialX + s.initialW - s.preview.minW,
        ).toInt();
        final int newH = (s.initialH + deltaY).clamp(
          s.preview.minH,
          widget.rows - s.initialY,
        ).toInt();
        p = p.copyWith(x: newX, w: s.initialX + s.initialW - newX, h: newH);
        break;
      default:
        break;
    }

    _activeSession.value = s.copyWith(
      preview: p,
      isOverGrid: overGrid,
      isValid: !_collision(p),
    );
  }

  void _endSession() {
    final s = _activeSession.value;
    if (s == null) return;

    if (!s.isFromDrawer && !s.isOverGrid) {
      widget.onModuleRemove(s.id);
    } else if (s.isValid && s.isOverGrid) {
      widget.onModuleUpdate(s.preview);
    }

    _activeSession.value = null;

    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb != null && _lastMousePosition != null) {
      final localMouse = _lastMousePosition!;
      final module = s.preview;
      final cellW = rb.size.width / widget.columns;
      final cellH = rb.size.height / widget.rows;

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
