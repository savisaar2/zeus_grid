import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  testWidgets('Module Spacing: should apply spacing between modules', (tester) async {
    final modules = [
      const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: modules,
            unplacedModules: const [],
            isEditing: false,
            spacing: 10.0,
            cellSide: 10.0,
            onGenerateContent: (id) => Container(key: Key('content_$id')),
            onModuleUpdate: (m) {},
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Module m1 is at (0,0) with size 10x10 cells. cellSide=10.
    // Total physical size = 100x100.
    // With spacing=10, the actual content should be inset by 5 on all sides (spacing/2).
    // Or if we follow standard gutter logic, it's just spacing between.
    // Let's say we apply half spacing as padding to each module container.
    
    final contentRect = tester.getRect(find.byKey(const Key('content_m1')));
    
    // Expected rect: left=6, top=6, width=88, height=88.
    // (5.0 padding + 1.0 border = 6.0 inset from each side)
    expect(contentRect.left, 6.0);
    expect(contentRect.top, 6.0);
    expect(contentRect.width, 88.0);
    expect(contentRect.height, 88.0);
  });
}
