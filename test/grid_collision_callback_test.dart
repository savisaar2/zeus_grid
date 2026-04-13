import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  testWidgets('Collision Callback: should trigger onCollisionDetected when autoPack is false and drop is invalid', (tester) async {
    ZeusModule? collidedModule;
    final modules = [
      const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
      const ZeusModule(id: 'm2', x: 15, y: 0, w: 10, h: 10),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: modules,
            unplacedModules: const [],
            isEditing: true,
            autoPack: false,
            onCollisionDetected: (m) => collidedModule = m,
            onGenerateContent: (id) => Container(key: Key('content_$id')),
            onModuleUpdate: (m) {},
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpAndSettle();

    // Drag m2 to overlap m1
    final centerOfM2 = tester.getCenter(find.byKey(const Key('content_m2')));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(centerOfM2);
    await gesture.down(centerOfM2);
    await tester.pump();
    
    // Move m2 to (5,0) which overlaps m1(0,0,10,10)
    final destination = centerOfM2 - const Offset(100, 0); // 10 units left
    await gesture.moveTo(destination);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(collidedModule, isNotNull);
    expect(collidedModule!.id, 'm2');
  });
}
