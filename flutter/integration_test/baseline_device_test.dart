import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/app/gearbound_app.dart';
import 'package:integration_test/integration_test.dart';

import '../tool/baseline_check.dart';
import 'shared_fixtures.g.dart';

/// Phase 00 on a device: the shared determinism fixtures replay identically
/// in the app's own compiled code on Android, and the app boots.
///
///   dart run tool/baseline_check.dart --write-device-fixtures
///   flutter test integration_test/baseline_device_test.dart -d emulator-5554
///   flutter drive --profile --driver test_driver/integration_test.dart \n///     --target integration_test/baseline_device_test.dart  # AOT on device
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('shared fixtures replay identically on this device', () {
    final result = runBaseline((rel) {
      final text = sharedFixtures[rel];
      if (text == null) throw StateError('fixture $rel was not bundled');
      return text;
    });
    debugPrint(
      'DEVICE BASELINE OK: ${result.checks} checks, '
      '${result.combatTraces} combat traces, '
      '${result.workshopCases} workshop cases',
    );
    expect(result.checks, greaterThanOrEqualTo(51));
  });

  testWidgets('the app boots to the campaign route', (tester) async {
    await tester.pumpWidget(const GearboundApp());
    // The hub appears once local progress has loaded; wait up to 10 s.
    final route = find.text('THE WASTELAND ROUTE', skipOffstage: false);
    for (var i = 0; i < 100 && route.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(CampaignHubScreen), findsOneWidget);
    expect(route, findsOneWidget);
    // A fresh install opens node 1 and keeps the rest locked.
    expect(find.text('The First Link', skipOffstage: false), findsOneWidget);
    expect(find.text('PLAY', skipOffstage: false), findsOneWidget);
  });
}
