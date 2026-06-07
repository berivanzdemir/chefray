import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chefray/main.dart';

void main() {
  testWidgets('ChefRay app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChefRayApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
