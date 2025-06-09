import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book/main.dart';

void main() {
  testWidgets('renders login screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
