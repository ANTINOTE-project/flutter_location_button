import 'dart:io';

import 'package:flutter_location_button/src/platform_interface/flutter_location_button_api.g.dart';

import 'flutter_location_button_android.dart';

typedef ButtonLocalization = Map<LocationButtonTextType, String>;

base class const LocationButtonEvent({required final int sessionHandle});

final class const LocationButtonResultEvent({
  required super.sessionHandle,
  required final bool granted,
}) extends LocationButtonEvent;

final class const LocationButtonDeathEvent({required super.sessionHandle})
    extends LocationButtonEvent;

abstract base class FlutterLocationButtonPlatform() {
  static FlutterLocationButtonPlatform? _instance;

  /// The default instance of [FlutterLocationButtonPlatform] to use.
  ///
  /// Defaults to [AndroidFlutterLocationButton].
  static FlutterLocationButtonPlatform get instance {
    if (_instance != null) return _instance!;

    if (Platform.isAndroid) {
      final instance = AndroidFlutterLocationButton();
      _instance = instance;
      instance.registerWith();

      return _instance!;
    }

    throw UnsupportedError(
      'flutter_location_button is unsupported on this platform.',
    );
  }

  Future<bool> createSession(int sessionHandle, RawLocationButtonStyle style) {
    throw UnimplementedError('No implementation for createSession.');
  }

  Future<void> updateButton(
    int sessionHandle,
    RawLocationButtonStyle oldStyle,
    RawLocationButtonStyle newStyle,
  ) {
    throw UnimplementedError('No implementation for updateButton.');
  }

  Future<void> closeSession(int sessionHandle) {
    throw UnimplementedError('No implementation for closeSession.');
  }

  Stream<LocationButtonEvent> get eventStream =>
      throw UnimplementedError('No implementation for eventStream.');

  Future<bool> askForBroaderPermission(int sessionHandle);

  ButtonLocalization? get localization;
  Stream<ButtonLocalization> get localizationStream;
}
