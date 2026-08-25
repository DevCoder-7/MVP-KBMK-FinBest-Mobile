import 'package:finbest_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('login fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const FinBestApp());

      expect(find.text('Selamat datang di FinBest AI'), findsOneWidget);
      expect(find.text('Masuk / Daftar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
