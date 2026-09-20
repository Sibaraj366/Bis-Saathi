import 'package:flutter_test/flutter_test.dart';
import 'package:bis_saathi/main.dart';

void main() {
  testWidgets('BIS Saathi app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BISSaathiApp());

    expect(find.text('BIS Saathi'), findsWidgets);
    expect(
      find.text('Your intelligent assistant for Indian Standards and BIS Services'),
      findsOneWidget,
    );
  });
}
