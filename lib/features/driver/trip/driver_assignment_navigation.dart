import 'package:flutter/material.dart';

import '../models/mock_ride_request.dart';
import 'driver_trip_confirmation_screen.dart';
import 'driver_pickup_screen.dart';
import 'driver_trip_in_progress_screen.dart';
import 'driver_cash_collection_screen.dart';

Future<void> openDriverAssignment(BuildContext context) async {
  final store = DriverDemoStore.instance;
  final requestId = store.activeAssignmentId;

  if (requestId == null) return;

  final request = store.requestFor(requestId);
  final bid = store.bidFor(requestId);
  final stage = store.assignmentStage(requestId);

  if (bid == null || stage == null) return;

  final Widget screen = switch (stage) {
    DemoAssignmentStage.selected => DriverTripConfirmationScreen(
      request: request,
      bid: bid,
    ),
    DemoAssignmentStage.confirmed || DemoAssignmentStage.arrived =>
      DriverPickupScreen(request: request, bid: bid),
    DemoAssignmentStage.inProgress => DriverTripInProgressScreen(
      request: request,
      bid: bid,
    ),
    DemoAssignmentStage.awaitingCash => DriverCashCollectionScreen(
      request: request,
      bid: bid,
    ),
  };

  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
