import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_location_button/src/platform_interface/flutter_location_button_api.g.dart';

import 'flutter_location_button_platform_interface.dart';

/// An implementation of [FlutterLocationButtonPlatform] for Android (using
/// Pigeon).
final class AndroidFlutterLocationButton extends FlutterLocationButtonPlatform
    implements LocationButtonCallback {
  /// The Pigeon API used to interact with the native platform.
  @visibleForTesting
  final api = LocationButtonApi();

  @override
  Future<bool> createSession(int sessionHandle, RawLocationButtonStyle style) =>
      api.createSession(sessionHandle, style);

  @override
  Future<void> updateButton(
    int sessionHandle,
    RawLocationButtonStyle oldStyle,
    RawLocationButtonStyle newStyle,
  ) => api.updateButton(sessionHandle, oldStyle, newStyle);

  @override
  Future<void> closeSession(int sessionHandle) =>
      api.closeSession(sessionHandle);

  final StreamController<LocationButtonEvent> _eventStreamController =
      StreamController.broadcast();

  @override
  Stream<LocationButtonEvent> get eventStream => _eventStreamController.stream;

  @override
  void permissionResult(int sessionHandle, bool granted) {
    _eventStreamController.add(
      LocationButtonResultEvent(sessionHandle: sessionHandle, granted: granted),
    );
  }

  @override
  void sessionDead(int sessionHandle) {
    _eventStreamController.add(
      LocationButtonDeathEvent(sessionHandle: sessionHandle),
    );
  }

  @override
  Future<bool> askForBroaderPermission(int sessionHandle) =>
      api.requestPermission(sessionHandle);

  ButtonLocalization? _curLocalization;

  @override
  ButtonLocalization? get localization => _curLocalization;

  final StreamController<ButtonLocalization> _localizationStreamController =
      StreamController.broadcast();

  @override
  Stream<ButtonLocalization> get localizationStream =>
      _localizationStreamController.stream;

  @override
  void newLocalizations(ButtonLocalization newLocalizations) {
    _curLocalization = newLocalizations;
    _localizationStreamController.add(newLocalizations);

    print('Got new localizations: $newLocalizations');
  }

  Future<void> registerWith() async {
    LocationButtonCallback.setUp(this);
    newLocalizations(await api.fetchLocalization());
  }
}
