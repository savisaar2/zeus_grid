import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  testWidgets('Custom Resize Handle: should render custom widget if provided', (WidgetTester tester) async {
    final module = ZeusModule(id: 'm1', x: 0, y: 0, w: 10, h: 10);
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeusGrid(
            modules: [module],
            unplacedModules: const [],
            isEditing: true,
            moduleStyle: ModuleStyle(
              resizeHandleBuilder: (direction) => Container(
                key: Key('custom_handle_${direction.name}'),
                color: Colors.red,
                width: 10,
                height: 10,
              ),
            ),
            onGenerateContent: (id) => Container(),
            onModuleUpdate: (m) {},
            onModuleRemove: (id) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger focus to show handles
    final center = tester.getCenter(find.byType(ZeusModuleWidget));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    // Check if custom handles are present
    expect(find.byKey(const Key('custom_handle_topLeft')), findsOneWidget);
    expect(find.byKey(const Key('custom_handle_bottomRight')), findsOneWidget);
    expect(find.byKey(const Key('custom_handle_right')), findsOneWidget);
  });
}
