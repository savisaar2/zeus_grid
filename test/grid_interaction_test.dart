import 'dart:ui'; // 🎯 Required for PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  testWidgets('Resize handles should be present in edit mode', (tester) async {
    const moduleId = 'resize_mod';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: const [
              ZeusModule(id: moduleId, x: 10, y: 10, w: 20, h: 20),
            ],
            unplacedModules: const [],
            isEditing: true,
            onGenerateContent: (id) => Container(key: Key('content_$id')),
            onModuleUpdate: (m) {},
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    // 🎯 1. Create a mouse-specific gesture
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

    // 🎯 2. "Plug in" the mouse and move it to the center of the module
    final center = tester.getCenter(find.byKey(const Key('content_$moduleId')));
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(center);

    // 🎯 3. Rebuild the frame so the state change (_focusedModuleId) triggers
    await tester.pump();

    // Now check for the handles (they are built inside your Stack)
    // You should find at least the close button and a few handles
    expect(find.byType(Listener), findsAtLeast(7));

    // Cleanup the gesture
    await gesture.removePointer();
  });
}
