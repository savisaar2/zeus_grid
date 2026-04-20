import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  testWidgets('ZeusGrid uses columns property to determine cell dimensions', (
    tester,
  ) async {
    const double gridWidth = 400.0;
    const double gridHeight = 400.0;
    const int numColumns = 4;

    final modules = [const ZeusModule(id: 'm1', x: 0, y: 0, w: 1, h: 1)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: ZeusGrid(
                modules: modules,
                unplacedModules: const [],
                isEditing: false,
                columns: numColumns, // Using columns instead of cellSide
                onGenerateContent: (id) => Container(key: Key('content_$id')),
                onModuleUpdate: (_) {},
                onModuleRemove: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The grid width is 400. There are 4 columns.
    // Each cell should be 400 / 4 = 100 wide and 100 high.
    // The module is at 0, 0 with w=1, h=1, so it should be 100x100.
    final moduleFinder = find.byType(ZeusModuleWidget);
    expect(moduleFinder, findsOneWidget);

    final size = tester.getSize(moduleFinder);
    expect(size.width, 100.0);
    expect(size.height, 100.0);
  });
}
