import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  testWidgets('Outside Window: dragging existing module outside window should NOT make it disappear', (tester) async {
    final modules = [
      const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: modules,
            unplacedModules: const [],
            isEditing: true,
            onGenerateContent: (id) => Container(key: Key('content_$id')),
            onModuleUpdate: (m) {},
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    tester.view.physicalSize = const Size(500, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpAndSettle();

    final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(centerOfM1);
    await gesture.down(centerOfM1);
    await tester.pump();
    
    // Move mouse far outside the window (500x500 window, move to 1000, 1000)
    await gesture.moveTo(const Offset(1000, 1000));
    await tester.pump();
    
    // Check if the ghost or the active module widget is still visible
    // Based on current logic, they should be gone (SizedBox.shrink)
    expect(find.byType(ZeusModuleWidget), findsWidgets, reason: 'Module should remain visible even when mouse is outside window');

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
