import 'package:campus_express/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding tampil saat belum login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CampusExpressApp()));
    await tester.pump();

    expect(find.text('Campus Express'), findsWidgets);
    expect(find.text('Pilih peranmu'), findsOneWidget);
    expect(find.text('Saya Konsumen'), findsOneWidget);
  });
}
