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

  group('Maximum Size Constraints', () {
    testWidgets(
      'Module should not be resized larger than maxW (right handle)',
      (tester) async {
        ZeusModule? updatedModule;
        // Initial w=10, maxW=15. Cell side is 10.0 by default.
        final module = ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10, maxW: 15);

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

        // Right edge is at x=100. Drag it to x=300 (which would be w=30)
        final rightEdge = centerOfModule + const Offset(45, 0);

        final dragGesture = await tester.startGesture(
          rightEdge,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await dragGesture.moveTo(centerOfModule + const Offset(200, 0));
        await tester.pump();
        await dragGesture.up();
        await tester.pumpAndSettle();

        expect(updatedModule, isNotNull);
        expect(updatedModule!.w, 15);
      },
    );

    testWidgets(
      'Module should not be resized larger than maxH (bottom handle)',
      (tester) async {
        ZeusModule? updatedModule;
        final module = ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10, maxH: 12);

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

        final bottomEdge = centerOfModule + const Offset(0, 45);

        final dragGesture = await tester.startGesture(
          bottomEdge,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await dragGesture.moveTo(centerOfModule + const Offset(0, 200));
        await tester.pump();
        await dragGesture.up();
        await tester.pumpAndSettle();

        expect(updatedModule, isNotNull);
        expect(updatedModule!.h, 12);
      },
    );
  });
}
