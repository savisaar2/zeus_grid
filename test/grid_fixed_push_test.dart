import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  testWidgets('Fixed Grid: modules should be pushed when viewport shrinks', (
    WidgetTester tester,
  ) async {
    final gridKey = GlobalKey();
    List<ZeusModule> modules = [
      const ZeusModule(id: 'm1', x: 90, y: 10, w: 10, h: 10),
    ];

    // 1. Set initial large size
    await tester.binding.setSurfaceSize(const Size(1000, 1000));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            key: gridKey,
            modules: modules,
            unplacedModules: const [],
            isEditing: true,
            cellSide: 10.0,
            onGenerateContent: (id) => Container(key: Key('content_$id')),
            onModuleUpdate: (m) {
              modules = [m];
            },
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    // Initial state check
    expect(modules[0].x, 90);

    // 2. Shrink viewport to 800px (80 columns)
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pump(); // Trigger layout builder update

    // Pump to allow postFrameCallback to fire
    await tester.pumpAndSettle();

    // Module should be reflowed to the first available slot (0,0)
    expect(modules[0].x, 0);
    expect(modules[0].y, 0);
  });

  testWidgets('Aspect Ratio Reflow: modules should scale to fit width', (
    WidgetTester tester,
  ) async {
    List<ZeusModule> modules = [
      const ZeusModule(
        id: 'wide',
        x: 0,
        y: 0,
        w: 100,
        h: 50,
        minW: 10,
        minH: 5,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1000, 1000));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: modules,
            unplacedModules: const [],
            isEditing: true,
            cellSide: 10.0,
            onGenerateContent: (id) => Container(),
            onModuleUpdate: (m) => modules = [m],
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    // Initial check: w=100
    expect(modules[0].w, 100);

    // Shrink viewport to 500px (50 columns)
    await tester.binding.setSurfaceSize(const Size(500, 500));
    await tester.pumpAndSettle();

    // Module was 100x50 (AR=2). New width should be 50.
    // New height should be 50 / 2 = 25.
    expect(modules[0].w, 50);
    expect(modules[0].h, 25);
  });

  testWidgets(
    'Fixed Grid: modules should stay in place if viewport is large enough',
    (WidgetTester tester) async {
      final gridKey = GlobalKey();
      List<ZeusModule> modules = [
        const ZeusModule(id: 'm1', x: 10, y: 10, w: 10, h: 10),
      ];

      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeusGrid(
              key: gridKey,
              modules: modules,
              unplacedModules: const [],
              isEditing: true,
              cellSide: 10.0,
              onGenerateContent: (id) => Container(key: Key('content_$id')),
              onModuleUpdate: (m) {
                modules = [m];
              },
              onModuleRemove: (id) {},
            ),
          ),
        ),
      );

      expect(modules[0].x, 10);

      // Shrink but not enough to touch the module (500px = 50 columns)
      await tester.binding.setSurfaceSize(const Size(500, 500));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(modules[0].x, 10);
    },
  );
}
