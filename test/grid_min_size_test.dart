import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  Widget buildTestGrid({
    required List<ZeusModule> modules,
    Function(ZeusModule)? onModuleUpdate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ZeusGrid(
          modules: modules,
          unplacedModules: const [],
          isEditing: true,
          onGenerateContent: (id) => Container(key: Key('content_$id')),
          onModuleUpdate: onModuleUpdate ?? (m) {},
          onModuleRemove: (id) {},
        ),
      ),
    );
  }

  group('Minimum Size Constraints', () {
    testWidgets('Module should not be resized smaller than minW (right handle)', (
      tester,
    ) async {
      ZeusModule? updatedModule;
      final module = ZeusModule(
        id: 'm1',
        x: 0,
        y: 0,
        w: 20,
        h: 20,
        minW: 5,
        minH: 5,
      );

      await tester.pumpWidget(
        buildTestGrid(
          modules: [module],
          onModuleUpdate: (m) => updatedModule = m,
        ),
      );

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfModule = tester.getCenter(
        find.byKey(const Key('content_m1')),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfModule);
      await tester.pumpAndSettle();

      // physicalW = 20 * 10 = 200. center is at (100, 100) + 30 padding?
      // wait, ZeusGrid is in a Stack. centerOfModule is (100, 100) if it's at (0,0).

      final rightEdge = centerOfModule + const Offset(95, 0);

      final dragGesture = await tester.startGesture(
        rightEdge,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await dragGesture.moveTo(centerOfModule - const Offset(80, 0));
      await tester.pump();
      await dragGesture.up();
      await tester.pumpAndSettle();

      expect(updatedModule, isNotNull);
      expect(updatedModule!.w, 5);
    });

    testWidgets(
      'Module should not be resized smaller than minH (bottom handle)',
      (tester) async {
        ZeusModule? updatedModule;
        final module = ZeusModule(
          id: 'm1',
          x: 0,
          y: 0,
          w: 20,
          h: 20,
          minW: 5,
          minH: 5,
        );

        await tester.pumpWidget(
          buildTestGrid(
            modules: [module],
            onModuleUpdate: (m) => updatedModule = m,
          ),
        );

        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpAndSettle();

        final centerOfModule = tester.getCenter(
          find.byKey(const Key('content_m1')),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(centerOfModule);
        await tester.pumpAndSettle();

        final bottomEdge = centerOfModule + const Offset(0, 95);

        final dragGesture = await tester.startGesture(
          bottomEdge,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await dragGesture.moveTo(centerOfModule - const Offset(0, 80));
        await tester.pump();
        await dragGesture.up();
        await tester.pumpAndSettle();

        expect(updatedModule, isNotNull);
        expect(updatedModule!.h, 5);
      },
    );

    testWidgets(
      'Module should not be resized smaller than minW/minH (topLeft handle)',
      (tester) async {
        ZeusModule? updatedModule;
        final module = ZeusModule(
          id: 'm1',
          x: 10,
          y: 10,
          w: 20,
          h: 20,
          minW: 5,
          minH: 5,
        );

        await tester.pumpWidget(
          buildTestGrid(
            modules: [module],
            onModuleUpdate: (m) => updatedModule = m,
          ),
        );

        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpAndSettle();

        final centerOfModule = tester.getCenter(
          find.byKey(const Key('content_m1')),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(centerOfModule);
        await tester.pumpAndSettle();

        final topLeftCorner = centerOfModule - const Offset(95, 95);

        final dragGesture = await tester.startGesture(
          topLeftCorner,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        // Drag towards bottom-right to make it smaller from top-left
        await dragGesture.moveTo(centerOfModule + const Offset(80, 80));
        await tester.pump();
        await dragGesture.up();
        await tester.pumpAndSettle();

        expect(updatedModule, isNotNull);
        expect(updatedModule!.w, 5);
        expect(updatedModule!.h, 5);
        // New X should be initialX + (initialW - minW) = 10 + (20 - 5) = 25
        expect(updatedModule!.x, 25);
        expect(updatedModule!.y, 25);
      },
    );
  });
}
