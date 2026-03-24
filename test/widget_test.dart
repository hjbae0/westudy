import 'package:flutter_test/flutter_test.dart';
import 'package:westudy/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
