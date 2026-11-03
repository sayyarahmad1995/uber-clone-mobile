import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/app/higo_theme.dart';
import 'package:uberclone/features/rider/booking/driver_offers_screen.dart';
import 'package:uberclone/features/rider/booking/location_selection_screen.dart';
import 'package:uberclone/features/rider/booking/mock_driver_offer.dart';
import 'package:uberclone/features/rider/booking/ride_category.dart';
import 'package:uberclone/features/rider/booking/widgets/nearby_drivers_mock_map.dart';

void main() {
  test('fare comparisons update without changing existing offers', () {
    final offers = mockOffersForFare(450);
    expect(offers.map((offer) => offer.id).toList(), [
      'driver_1',
      'driver_2',
      'driver_3',
      'driver_4',
      'driver_5',
    ]);
    expect(offers.first.farePkr, 450);
    expect(compareDriverFare(450, 450), 'Matches your offer');
    expect(compareDriverFare(480, 450), '+ PKR 30');
    expect(compareDriverFare(480, 500), 'PKR 20 below your offer');
    expect(offers[1].farePkr, 480);
    expect(formatOfferFare(12500), 'PKR 12,500');
  });

  testWidgets('offers appear, decline individually, and preserve the request', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    expect(find.text('Waiting for driver offers'), findsNothing);
    expect(find.text('Looking for offers · Map preview'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Safety and help'), findsOneWidget);
    expect(find.byKey(const Key('offers-floating-controls')), findsOneWidget);
    expect(find.byKey(const Key('rider-scanning-animation')), findsOneWidget);
    expect(find.byKey(const Key('mock-rider-location')), findsOneWidget);
    expect(find.byKey(const Key('mock-driver-1')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.text('Driver offers'), findsNothing);
    expect(find.byKey(const Key('rider-scanning-animation')), findsNothing);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);

    await tester.tap(find.text('Decline').first);
    await tester.pump();
    expect(find.text('Ahmed Khan'), findsNothing);
    expect(find.text('Waiting for more offers'), findsNothing);
    expect(find.byKey(const Key('rider-scanning-animation')), findsOneWidget);
    expect(find.text('Increase fare'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Bilal Ahmed'), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsNothing);
  });

  testWidgets('edge-to-edge map and floating controls stay behind bids', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, Colors.white);

    final statusStyle = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(statusStyle.value.statusBarColor, Colors.transparent);
    expect(statusStyle.value.statusBarIconBrightness, Brightness.dark);
    expect(find.byKey(const Key('offers-floating-controls')), findsOneWidget);
    expect(find.text('Driver offers'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.byKey(const Key('mock-rider-location')), findsOneWidget);
    expect(find.text('Looking for offers · Map preview'), findsNothing);
  });

  testWidgets('scanning pulse expands only while waiting for offers', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    final pulse = find.byKey(const Key('rider-scanning-pulses'));
    final first = (tester.widget<CustomPaint>(pulse).painter!
            as RiderScanningPulsePainter)
        .progress;
    await tester.pump(const Duration(milliseconds: 450));
    final second = (tester.widget<CustomPaint>(pulse).painter!
            as RiderScanningPulsePainter)
        .progress;
    expect(second, isNot(first));

    await tester.pump(const Duration(milliseconds: 1550));
    await tester.pump();
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(pulse, findsNothing);
  });

  testWidgets('reduced motion displays the rider without animating', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HiGoTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 780),
            disableAnimations: true,
          ),
          child: _testScreen(),
        ),
      ),
    );
    final pulse = tester.widget<CustomPaint>(
      find.byKey(const Key('rider-scanning-pulses')),
    );
    expect((pulse.painter! as RiderScanningPulsePainter).progress, 0);
    expect(find.byKey(const Key('mock-rider-location')), findsOneWidget);
  });

  testWidgets('raising rider fare preserves existing bid prices', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Matches your offer'), findsOneWidget);
    expect(find.text('PKR 450'), findsWidgets);

    await tester.tap(find.text('Increase fare').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '500');
    await tester.tap(find.text('Increase fare').last);
    await tester.pumpAndSettle();

    expect(find.text('PKR 500'), findsOneWidget);
    expect(find.text('PKR 450'), findsOneWidget);
    expect(find.text('PKR 50 below your offer'), findsOneWidget);
  });

  testWidgets('choosing waits for an explicit mock driver response', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Waiting for driver confirmation'), findsOneWidget);
    expect(find.text('Demo: Driver confirms'), findsOneWidget);
    expect(find.text('Demo: Driver declines'), findsOneWidget);

    await tester.tap(find.text('Demo: Driver declines'));
    await tester.pump();
    // Do not pumpAndSettle while the empty-offers scanner repeats.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('offers-floating-controls')), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsNothing);
    expect(find.text('Increase fare'), findsOneWidget);
  });

  testWidgets('unseen offers are announced when browsing older ones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('1 new offer'), findsOneWidget);

    await tester.tap(find.text('1 new offer'));
    await tester.pumpAndSettle();
    expect(find.text('1 new offer'), findsNothing);
  });

  testWidgets('compact layout keeps controls available at larger text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: HiGoTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.4),
          ),
          child: _testScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Increase fare'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
  });
}

Widget _testApp() => MaterialApp(
  theme: HiGoTheme.light,
  home: _testScreen(),
);

Widget _testScreen() => DriverOffersScreen(
    locations: const SelectedLocations(
      pickup: 'F-7 Markaz',
      destination: 'Centaurus Mall',
    ),
    rideCategory: const RideCategory(
      id: 'test',
      name: 'Mini Car',
      description: 'Demo ride',
      icon: Icons.directions_car,
      estimatedFarePkr: 450,
    ),
  );
