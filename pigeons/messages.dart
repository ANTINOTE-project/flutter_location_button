import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/platform_interface/flutter_location_button_api.g.dart',
    kotlinOut: 'android/src/main/kotlin/fr/antinote/flutter_location_button/GeneratedFlutterLocationButtonApi.kt',
    kotlinOptions: KotlinOptions(
      package: 'fr.antinote.flutter_location_button',
    ),
  ),
)
/// Describes the text label to put on the Location Button.
enum LocationButtonTextType {
  /// The button won't contain any text.
  none,

  /// The button will have the localized label "Precise location".
  preciseLocation,

  /// The button will have the localized label "Use precise location".
  usePreciseLocation,

  /// The button will have the localized label "Share precise location".
  sharePreciseLocation,

  /// The button will have the localized label "Near my precise location".
  nearMyPreciseLocation,

  /// The button will have the localized label "Near your precise location".
  nearYourPreciseLocation,
}

/// Describes the appearance of the Location Button.
class RawLocationButtonStyle {
  /// The height of the button, between 48dp and 136dp (inclusive).
  late final int height;

  /// The width of the button, at least 48dp.
  late final int width;

  /// The ARGB value for the background color. The alpha channel is
  /// automatically overridden to opaque.
  late final int? backgroundColor;

  /// The ARGB value for the tint of the icon of the button. The minimum
  /// contrast ratio for the tint is 4.5:1. The system may shift the color of
  /// the icon to satisfy this constraint.
  late final int? iconTintColor;

  /// The ARGB value for the color of the text of the button (if present). The
  /// minimum contrast ratio for the color is 4.5:1. The system may shift the
  /// color of the text to satisfy this constraint.
  late final int? textColor;

  /// The type of label to display on top of the bottom.
  late final LocationButtonTextType textType;

  /// The color of the outline around the button. Defaults to the
  /// [backgroundColor].
  late final int? strokeColor;

  /// The thickness of the outline formed around the button. The value ranges
  /// between 0dp and 3dp (inclusive).
  late final int strokeWidth;

  /// The bottom padding for the button. Ranges between 4dp and 8dp (inclusive).
  late final int? bottomPadding;

  /// The left padding for the button. Ranges between 4dp and 8dp (inclusive).
  late final int? leftPadding;

  /// The right padding for the button. Ranges between 4dp and 8dp (inclusive).
  late final int? rightPadding;

  /// The top padding for the button. Ranges between 4dp and 8dp (inclusive).
  late final int? topPadding;

  /// Corner radius for the button when it is unpressed. Must be positive.
  late final double? cornerRadius;

  /// Corner radius for the button when it is pressed. Must be positive.
  late final double? pressedCornerRadius;
}

@HostApi()
abstract class LocationButtonApi {
  /// Creates a Location Button session that starts drawing the button on
  /// screen.
  @async
  bool createSession(int sessionHandle, RawLocationButtonStyle style);

  /// Updates visually the button to match the [newStyle].
  void updateButton(
    int sessionHandle,
    RawLocationButtonStyle oldStyle,
    RawLocationButtonStyle newStyle,
  );

  /// Closes definitively the session and stops the button from drawing /
  /// working.
  void closeSession(int sessionHandle);

  /// Asks the user for the broader location permission, if possible. Returns
  /// true if granted.
  @async
  @asyncCallback
  bool requestPermission(int sessionHandle);

  /// Asks for the button text localizations explicitly (we use this so that we
  /// can fetch them when we hot restart...)
  Map<LocationButtonTextType, String> fetchLocalization();
}

@FlutterApi()
abstract class LocationButtonCallback {
  /// Called when the user pressed the Location Button and picked whether to
  /// temporarily grant the precise location permission.
  void permissionResult(int sessionHandle, bool granted);

  /// Called when the session prematurely dies, for whatever reason.
  void sessionDead(int sessionHandle);

  /// Called when the language for the app changes.
  void newLocalizations(Map<LocationButtonTextType, String> newLocalizations);
}
