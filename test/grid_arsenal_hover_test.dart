import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  testWidgets(
    'Arsenal Hover: dragging existing module over arsenal should NOT set overGrid to false',
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

      // If overGrid is false, the ghost should disappear.
      // The ValueListenableBuilder for _activeSession returns SizedBox.shrink() if !session.isOverGrid.
      expect(
        find.byType(ZeusModuleWidget),
        findsNWidgets(1),
      ); // Only the static one?
      // Wait, the active one is also a ZeusModuleWidget.
      // If session.isOverGrid is true, we should have 2 ZeusModuleWidgets (one static hidden by wrapper, one active).
      // Actually _ModuleWrapper returns SizedBox.shrink() if isCurrentlyActive.
      // So there should be exactly 1 ZeusModuleWidget visible (the active one).

      // Let's check for the ghost container instead.
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
        isFalse,
        reason:
            'Module should not be removed when hovering arsenal during drag',
      );
    },
  );
}
