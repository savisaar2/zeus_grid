import 'package:flutter/material.dart';
import 'src/models.dart';
import 'src/grid_painter.dart';

export 'src/models.dart';

class ZeusGrid extends StatefulWidget {
  final List<ZeusModule> modules;
  final List<ZeusModule> unplacedModules;
  final bool isEditing;
  final Widget Function(String id) onGenerateContent;
  final Function(ZeusModule) onModuleUpdate;
  final Function(String) onModuleRemove;
  final int columns;
  final int rows;
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

class _ZeusGridState extends State<ZeusGrid> {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<ZeusSession?> _activeSession = ValueNotifier(null);
  String? _focusedModuleId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.columns;
        final cellH = constraints.maxHeight / widget.rows;

        return Stack(
          children: [
            Container(color: Colors.black),
            _buildVirtualGrid(cellW, cellH),
            _buildArsenalDrawer(widget.isEditing, cellW, cellH),
          ],
        );
      },
    );
  }

  // --- Grid & Module Logic ---

  Widget _buildVirtualGrid(double cellW, double cellH) {
    return ValueListenableBuilder<ZeusSession?>(
      valueListenable: _activeSession,
      builder: (context, session, _) {
        final list = List<ZeusModule>.from(widget.modules);
        if (session != null && session.isFromDrawer && session.isOverGrid) {
          if (!list.any((m) => m.id == session.id)) list.add(session.preview);
        }
        list.sort(
          (a, b) => (a.id == session?.id || a.id == _focusedModuleId) ? 1 : -1,
        );

        return Stack(
          key: _gridKey,
          clipBehavior: Clip.none,
          children: [
            if (widget.isEditing)
              CustomPaint(
                size: Size.infinite,
                painter: GridPainter(
                  style: widget.gridStyle,
                  cellW: cellW,
                  cellH: cellH,
                  rows: widget.rows,
                  cols: widget.columns,
                ),
              ),
            ...list.map((m) => _buildModuleWrapper(m, session, cellW, cellH)),
          ],
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

    final int x = isActive ? session!.preview.x : m.x;
    final int y = isActive ? session!.preview.y : m.y;
    final int w = isActive ? session!.preview.w : m.w;
    final int h = isActive ? session!.preview.h : m.h;

    // --- ENFORCE PHYSICAL LIMITS ---
    // We calculate what the width/height SHOULD be based on the grid.
    double calculatedW = w * cellW;
    double calculatedH = h * cellH;

    // We define a "Floor".
    // Option A: Use a fixed minimum (e.g., 100px).
    // Option B: Use a relative minimum (e.g., m.minW * 30px) so small modules
    // can stay smaller than large modules.
    double minPhysicalW =
        m.minW * 20.0; // Adjust '20.0' to your preferred minimum cell size
    double minPhysicalH = m.minH * 20.0;

    final double finalW = calculatedW.clamp(minPhysicalW, double.infinity);
    final double finalH = calculatedH.clamp(minPhysicalH, double.infinity);

    return Positioned(
      left: (x * cellW) - 30,
      top: (y * cellH) - 30,
      width: finalW + 60, // The 60 adds padding for the resize handles
      height: finalH + 60,
      child: MouseRegion(
        onEnter: (_) =>
            widget.isEditing ? setState(() => _focusedModuleId = m.id) : null,
        onExit: (_) =>
            widget.isEditing ? setState(() => _focusedModuleId = null) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCard(m, isActive, isFocused, isValid),
            if (widget.isEditing) ..._buildControls(m, cellW, cellH),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ZeusModule m, bool isActive, bool isFocused, bool isValid) {
    final border = (isFocused || isActive)
        ? (isValid
              ? widget.moduleStyle.activeBorderColor
              : widget.moduleStyle.warningBorderColor)
        : (widget.isEditing ? Colors.white.withAlpha(26) : Colors.transparent);

    return Positioned(
      left: 30,
      top: 30,
      right: 30,
      bottom: 30,
      child: Opacity(
        opacity: isActive ? widget.moduleStyle.activeOpacity : 1.0,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => widget.isEditing ? _startSession(m, e) : null,
          onPointerMove: (e) => _updateSession(e),
          onPointerUp: (_) => _endSession(),
          child: Container(
            decoration: BoxDecoration(
              color: widget.moduleStyle.color,
              border: Border.all(
                color: border,
                width: (isFocused || isActive) ? 2.0 : 1.0,
              ),
              borderRadius: widget.moduleStyle.borderRadius,
            ),
            child: ClipRRect(
              borderRadius: widget.moduleStyle.borderRadius,
              child: IgnorePointer(
                ignoring: widget.isEditing,
                child: widget.onGenerateContent(m.id),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Controls & Session ---

  List<Widget> _buildControls(ZeusModule m, double cellW, double cellH) {
    return [
      _handle(
        m,
        HandleType.top,
        cellW,
        cellH,
        top: 40,
        left: 70,
        right: 70,
        height: 45,
        bW: 30,
        bH: 3,
        align: Alignment.topCenter,
      ),
      _handle(
        m,
        HandleType.bottom,
        cellW,
        cellH,
        bottom: 40,
        left: 70,
        right: 70,
        height: 45,
        bW: 30,
        bH: 3,
        align: Alignment.bottomCenter,
      ),
      _handle(
        m,
        HandleType.left,
        cellW,
        cellH,
        left: 40,
        top: 70,
        bottom: 70,
        width: 45,
        bW: 3,
        bH: 30,
        align: Alignment.centerLeft,
      ),
      _handle(
        m,
        HandleType.right,
        cellW,
        cellH,
        right: 40,
        top: 70,
        bottom: 70,
        width: 45,
        bW: 3,
        bH: 30,
        align: Alignment.centerRight,
      ),
      _handle(
        m,
        HandleType.topLeft,
        cellW,
        cellH,
        top: 30,
        left: 30,
        width: 50,
        height: 50,
        isCorner: true,
      ),
      _handle(
        m,
        HandleType.bottomLeft,
        cellW,
        cellH,
        bottom: 30,
        left: 30,
        width: 50,
        height: 50,
        isCorner: true,
      ),
      _handle(
        m,
        HandleType.bottomRight,
        cellW,
        cellH,
        bottom: 30,
        right: 30,
        width: 50,
        height: 50,
        isCorner: true,
      ),
      Positioned(
        right: 20,
        top: 20,
        child: GestureDetector(
          onTap: () => widget.onModuleRemove(m.id),
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ),
    ];
  }

  Widget _handle(
    ZeusModule m,
    HandleType t,
    double cW,
    double cH, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
    double? bW,
    double? bH,
    Alignment align = Alignment.center,
    bool isCorner = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _startSession(m, e, t),
        onPointerMove: (e) => _updateSession(e),
        onPointerUp: (_) => _endSession(),
        child: Align(
          alignment: align,
          child: isCorner
              ? _corner(t)
              : Container(width: bW, height: bH, color: Colors.white),
        ),
      ),
    );
  }

  Widget _corner(HandleType t) {
    const s = 14.0;
    const th = 3.5;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        border: Border(
          top: (t == HandleType.topLeft)
              ? const BorderSide(color: Colors.white, width: th)
              : BorderSide.none,
          bottom: (t == HandleType.bottomLeft || t == HandleType.bottomRight)
              ? const BorderSide(color: Colors.white, width: th)
              : BorderSide.none,
          left: (t == HandleType.topLeft || t == HandleType.bottomLeft)
              ? const BorderSide(color: Colors.white, width: th)
              : BorderSide.none,
          right: (t == HandleType.bottomRight)
              ? const BorderSide(color: Colors.white, width: th)
              : BorderSide.none,
        ),
      ),
    );
  }

  void _startSession(
    ZeusModule m,
    PointerDownEvent e, [
    HandleType t = HandleType.move,
    bool fromDrawer = false,
  ]) {
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final cellW = rb.size.width / widget.columns;
    final cellH = rb.size.height / widget.rows;
    final local = rb.globalToLocal(e.position);
    final anchor = fromDrawer
        ? Offset((m.w * cellW) / 2, (m.h * cellH) / 2)
        : local - Offset(m.x * cellW, m.y * cellH);
    _activeSession.value = ZeusSession(
      id: m.id,
      preview: m.copy(),
      handle: t,
      anchor: anchor,
      isFromDrawer: fromDrawer,
    );
  }

  void _updateSession(PointerMoveEvent e) {
    final s = _activeSession.value;
    if (s == null) return;
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final cellW = rb.size.width / widget.columns;
    final cellH = rb.size.height / widget.rows;
    final local = rb.globalToLocal(e.position);
    final overGrid =
        e.position.dx <
        (MediaQuery.of(context).size.width - widget.menuStyle.width);

    ZeusModule p = s.preview;
    if (s.handle == HandleType.move) {
      final target = local - s.anchor;
      p = p.copyWith(
        x: (target.dx / cellW).round().clamp(0, widget.columns - p.w),
        y: (target.dy / cellH).round().clamp(0, widget.rows - p.h),
      );
    } else {
      p = _resize(
        p,
        (local.dx / cellW).round(),
        (local.dy / cellH).round(),
        s.handle,
      );
    }
    _activeSession.value = ZeusSession(
      id: s.id,
      preview: p,
      anchor: s.anchor,
      handle: s.handle,
      isValid: !_collision(p),
      isFromDrawer: s.isFromDrawer,
      isOverGrid: overGrid,
    );
  }

  ZeusModule _resize(ZeusModule p, int gX, int gY, HandleType t) {
    int x = p.x;
    int y = p.y;
    int w = p.w;
    int h = p.h;
    final r = x + w;
    final b = y + h;

    final name = t.name.toLowerCase();

    // 1. VERTICAL LOGIC (Independent)
    if (name.contains('top')) {
      y = gY.clamp(0, b - p.minH);
      h = b - y;
    } else if (name.contains('bottom')) {
      h = (gY - y).clamp(p.minH, widget.rows - y);
    }

    // 2. HORIZONTAL LOGIC (Independent)
    if (name.contains('left')) {
      x = gX.clamp(0, r - p.minW);
      w = r - x;
    } else if (name.contains('right')) {
      w = (gX - x).clamp(p.minW, widget.columns - x);
    }

    return p.copyWith(x: x, y: y, w: w, h: h);
  }

  void _endSession() {
    final s = _activeSession.value;
    if (s != null && s.isValid && (s.isFromDrawer ? s.isOverGrid : true))
      widget.onModuleUpdate(s.preview);
    _activeSession.value = null;
  }

  bool _collision(ZeusModule t) {
    for (var o in widget.modules) {
      if (o.id == t.id) continue;
      if (t.x < (o.x + o.w) &&
          (t.x + t.w) > o.x &&
          t.y < (o.y + o.h) &&
          (t.y + t.h) > o.y)
        return true;
    }
    return false;
  }

  // --- Arsenal Side Drawer ---

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Text(
                widget.menuStyle.title,
                style: widget.menuStyle.titleStyle,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.unplacedModules.length,
                itemBuilder: (context, i) {
                  final m = widget.unplacedModules[i];
                  return Listener(
                    onPointerDown: (e) =>
                        _startSession(m, e, HandleType.move, true),
                    onPointerMove: (e) => _updateSession(e),
                    onPointerUp: (_) => _endSession(),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        border: Border.all(color: Colors.white.withAlpha(26)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
