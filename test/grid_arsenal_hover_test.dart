import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  testWidgets(
    'Arsenal Hover: dragging existing module over arsenal SHOULD set isOverArsenal to true and remove on release',
    (tester) async {
      bool removed = false;
      final modules = [const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeusGrid(
              modules: modules,
              unplacedModules: const [],
              isEditing: true,
              menuStyle: const ZeusMenuStyle(width: 200),
              onGenerateContent: (id) => Container(key: Key('content_$id')),
              onModuleUpdate: (m) {},
              onModuleRemove: (id) => removed = true,
            ),
          ),
        ),
      );

      // Grid is likely 800 wide in default test environment if not specified,
      // but let's set it explicitly.
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfM1);
      await gesture.down(centerOfM1);
      await tester.pump();

      // Arsenal is at right=0, width=200. So it's from x=800 to x=1000.
      // Move to x=950 (well inside arsenal)
      await gesture.moveTo(const Offset(950, 500));
      await tester.pump();

      // Ghost should still be visible because overGrid remains true for existing modules
      // while hovering arsenal (to provide feedback).
      expect(find.byType(ZeusModuleWidget), findsNWidgets(1));

      expect(
        find.byType(Container).evaluate().any((e) {
          final container = e.widget as Container;
          return container.decoration is BoxDecoration &&
              (container.decoration as BoxDecoration).border != null;
        }),
        isTrue,
        reason: 'Ghost should still be visible even when hovering arsenal',
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        removed,
        isTrue,
        reason:
            'Module SHOULD be removed when released well inside arsenal during drag',
      );
    },
  );
}
