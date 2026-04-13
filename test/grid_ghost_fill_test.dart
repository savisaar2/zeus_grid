import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';
import 'dart:ui';

void main() {
  testWidgets('Ghost Fill: ghost preview should have a fill color', (
    tester,
  ) async {
    final modules = [const ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10)];

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

    await tester.pumpAndSettle();

    final centerOfM1 = tester.getCenter(find.byKey(const Key('content_m1')));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(centerOfM1);
    await gesture.down(centerOfM1);
    await tester.pump();

    // Check for the ghost container fill
    final ghostContainerFinder = find.byType(Container).evaluate().where((e) {
      final container = e.widget as Container;
      return container.decoration is BoxDecoration &&
          (container.decoration as BoxDecoration).color != null &&
          (container.decoration as BoxDecoration).border != null;
    });

    expect(
      ghostContainerFinder.length,
      greaterThan(0),
      reason: 'Ghost should have both fill color and border',
    );

    final ghostBox =
        (ghostContainerFinder.first.widget as Container).decoration
            as BoxDecoration;
    expect(
      ghostBox.color!.a,
      closeTo(20 / 255, 0.01),
      reason: 'Ghost fill should have expected alpha',
    );
  });
}
