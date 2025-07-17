// This is a basic Flutter widget test for the Islamic Kit example app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Islamic Kit example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed.
    expect(find.text('Islamic Kit Example'), findsOneWidget);
    
    // Verify that the main tabs are present.
    expect(find.text('Prayer Times'), findsOneWidget);
    expect(find.text('Hijri Calendar'), findsOneWidget);
    expect(find.text('Qibla Compass'), findsOneWidget);
    expect(find.text('Islamic Events'), findsOneWidget);
    expect(find.text('Zakat Calculator'), findsOneWidget);
    
    // Verify that the TabBar is present.
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(DefaultTabController), findsOneWidget);
  });
}
