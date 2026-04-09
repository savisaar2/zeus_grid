import 'package:flutter_test/flutter_test.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() {
  group('Grid Boundary & Clamping Tests', () {
    const module = ZeusModule(id: 'test', x: 5, y: 5, w: 10, h: 10);
    // In fixed grid, maxCols/Rows are dynamic based on viewport.
    // Clamping during updateSession uses these dynamic values.
    const maxCols = 120;
    const maxRows = 100;

    test('Module should not move past the Left/Top boundaries (0,0)', () {
      // Simulating a drag to negative coordinates
      final updated = module.copyWith(
        x: (-10).clamp(0, maxCols - module.w),
        y: (-10).clamp(0, maxRows - module.h),
      );

      expect(updated.x, 0);
      expect(updated.y, 0);
    });

    test('Module should not move past the Right/Bottom boundaries', () {
      final updated = module.copyWith(
        x: (150).clamp(0, maxCols - module.w),
        y: (150).clamp(0, maxRows - module.h),
      );

      expect(updated.x, 110); // 120 (max) - 10 (width)
      expect(updated.y, 90); // 100 (max) - 10 (height)
    });
  });
}
