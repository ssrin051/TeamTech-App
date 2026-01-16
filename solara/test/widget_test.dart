import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solara/main.dart';

void main() {
testWidgets('Leash Distance slider renders and responds to drag',
    (WidgetTester tester) async {
  await tester.pumpWidget(const MyToggleDemo());

  //Verify label text
  expect(find.text('Leash Distance'), findsOneWidget);

  //Find slider by type
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsOneWidget);

  // Drag slider
  await tester.drag(sliderFinder, const Offset(150, 0));
  await tester.pumpAndSettle();

  //Verify value changed
  final Slider sliderWidget = tester.widget(sliderFinder);
  expect(sliderWidget.value, greaterThan(0));
});

}
