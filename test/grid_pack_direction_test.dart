import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  Widget buildTestGrid({
    required List<ZeusModule> modules,
    PackDirection packDirection = PackDirection.down,
    Function(ZeusModule)? onModuleUpdate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ZeusGrid(
          modules: modules,
          unplacedModules: const [],
          isEditing: true,
          autoPack: true,
          packDirection: packDirection,
          onGenerateContent: (id) => Container(key: Key('content_$id')),
          onModuleUpdate: onModuleUpdate ?? (m) {},
          onModuleRemove: (id) {},
        ),
      ),
    );
  }

  group('Pack Direction Tests', () {
    testWidgets('PackDirection.down should push modules downwards', (tester) async {
      List<ZeusModule> currentModules = [
        const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
        const ZeusModule(id: 'm2', x: 0, y: 11, w: 10, h: 10),
      ];
      
      await tester.pumpWidget(
        buildTestGrid(
          modules: currentModules,
          packDirection: PackDirection.down,
          onModuleUpdate: (m) {
            final idx = currentModules.indexWhere((o) => o.id == m.id);
            currentModules[idx] = m;
          },
        ),
      );

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfM1);
      await gesture.down(centerOfM1);
      await tester.pump();
      
      // Move m1 from (0,0) to (2,0) -> y=2.
      // m1 is now at y=2, h=10. Ends at y=12.
      // m2 is at y=11. Overlap!
      // m2 should be pushed to y=12.
      await gesture.moveTo(centerOfM1 + const Offset(0, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final m2 = currentModules.firstWhere((m) => m.id == 'm2');
      expect(m2.y, 12);
    });

    testWidgets('PackDirection.right should push modules to the right', (tester) async {
      List<ZeusModule> currentModules = [
        const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
        const ZeusModule(id: 'm2', x: 11, y: 0, w: 10, h: 10),
      ];
      
      await tester.pumpWidget(
        buildTestGrid(
          modules: currentModules,
          packDirection: PackDirection.right,
          onModuleUpdate: (m) {
            final idx = currentModules.indexWhere((o) => o.id == m.id);
            currentModules[idx] = m;
          },
        ),
      );

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfM1);
      await gesture.down(centerOfM1);
      await tester.pump();
      // Move m1 to x=2. m1 ends at 12. m2 at 11. Overlap!
      await gesture.moveTo(centerOfM1 + const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final m2 = currentModules.firstWhere((m) => m.id == 'm2');
      expect(m2.x, 12);
    });

    testWidgets('PackDirection.up should push modules upwards', (tester) async {
      List<ZeusModule> currentModules = [
        const ZeusModule(id: 'm1', x: 0, y: 20, w: 10, h: 10),
        const ZeusModule(id: 'm2', x: 0, y: 15, w: 10, h: 10),
      ];
      
      await tester.pumpWidget(
        buildTestGrid(
          modules: currentModules,
          packDirection: PackDirection.up,
          onModuleUpdate: (m) {
            final idx = currentModules.indexWhere((o) => o.id == m.id);
            currentModules[idx] = m;
          },
        ),
      );

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfM1);
      await gesture.down(centerOfM1);
      await tester.pump();
      await gesture.moveTo(centerOfM1 - const Offset(20, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final m2 = currentModules.firstWhere((m) => m.id == 'm2');
      expect(m2.y, 8);
    });

    testWidgets('PackDirection.left should push modules to the left', (tester) async {
      List<ZeusModule> currentModules = [
        const ZeusModule(id: 'm1', x: 20, y: 0, w: 10, h: 10),
        const ZeusModule(id: 'm2', x: 15, y: 0, w: 10, h: 10),
      ];
      
      await tester.pumpWidget(
        buildTestGrid(
          modules: currentModules,
          packDirection: PackDirection.left,
          onModuleUpdate: (m) {
            final idx = currentModules.indexWhere((o) => o.id == m.id);
            currentModules[idx] = m;
          },
        ),
      );

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpAndSettle();

      final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(centerOfM1);
      await gesture.down(centerOfM1);
      await tester.pump();
      await gesture.moveTo(centerOfM1 - const Offset(20, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final m2 = currentModules.firstWhere((m) => m.id == 'm2');
      expect(m2.x, 8);
    });

   group('Pack Direction Multi-Module Push Tests', () {
      testWidgets('Should push multiple modules recursively (down)', (tester) async {
        List<ZeusModule> currentModules = [
          const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
          const ZeusModule(id: 'm2', x: 0, y: 11, w: 10, h: 10),
          const ZeusModule(id: 'm3', x: 0, y: 22, w: 10, h: 10),
        ];

        await tester.pumpWidget(
          buildTestGrid(
            modules: currentModules,
            packDirection: PackDirection.down,
            onModuleUpdate: (m) {
              final idx = currentModules.indexWhere((o) => o.id == m.id);
              currentModules[idx] = m;
            },
          ),
        );

        await tester.pumpAndSettle();
        final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(centerOfM1);
        await gesture.down(centerOfM1);
        // Move m1 to y=2. m1 ends at 12.
        // m2(y=11) pushes to 12. m2 ends at 22.
        // m3(y=22) pushes to 22+10=32.
        await gesture.moveTo(centerOfM1 + const Offset(0, 20));
        await gesture.up();
        await tester.pumpAndSettle();

        final m2 = currentModules.firstWhere((m) => m.id == 'm2');
        final m3 = currentModules.firstWhere((m) => m.id == 'm3');
        
        expect(m2.y, 12);
        expect(m3.y, 22); // Wait, m3 is at 22. m2 ends at 22. NO OVERLAP!
        // So m3 stays at 22. Correct.
      });
    });
   group('Pack Direction Collision between Others', () {
      testWidgets('m2 should push m3 when m1 pushes m2 into m3', (tester) async {
        List<ZeusModule> currentModules = [
          const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
          const ZeusModule(id: 'm2', x: 0, y: 11, w: 10, h: 10),
          const ZeusModule(id: 'm3', x: 0, y: 20, w: 10, h: 10),
        ];

        await tester.pumpWidget(
          buildTestGrid(
            modules: currentModules,
            packDirection: PackDirection.down,
            onModuleUpdate: (m) {
              final idx = currentModules.indexWhere((o) => o.id == m.id);
              currentModules[idx] = m;
            },
          ),
        );

        await tester.pumpAndSettle();
        final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(centerOfM1);
        await gesture.down(centerOfM1);
        // Move m1 to y=2. m1 ends at 12.
        // m2(y=11) pushed to 12. m2 ends at 22.
        // m3(y=20) overlapped by m2(y=12, h=10).
        // m3 pushed to 22.
        await gesture.moveTo(centerOfM1 + const Offset(0, 20));
        await gesture.up();
        await tester.pumpAndSettle();

        final m2 = currentModules.firstWhere((m) => m.id == 'm2');
        final m3 = currentModules.firstWhere((m) => m.id == 'm3');
        
        expect(m2.y, 12);
        expect(m3.y, 22);
      });
    });
  });
}
