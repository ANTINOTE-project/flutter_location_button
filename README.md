# Flutter Location Button

Display a system-rendered [Location Button](https://developer.android.com/guide/topics/permissions/private-alternatives/location-button)
(on Android 17+) with fallback options.

With it, you can ask the user for access to the device's location that is revoked when the app is
closed. On other OSes and on Android 16 and previous versions, a Flutter-rendered button that is an
equivalent to the native button will appear.

This button is preferred for user privacy and is easier to justify when publishing an app to the
[Play Store](https://support.google.com/googleplay/android-developer/answer/16909972#location-permissions)
(or other stores with similar policies).

We are agnostic regarding which geolocation solution you use
([`geolocator`](https://pub.dev/packages/geolocator),
[`location`](https://pub.dev/packages/location), or another one), you won't have to update
legacy code when migrating to this library, and you will use mature and familiar APIs.

## Getting Started
### Android Setup
The package already requests the new permission for the Location Button on Android 17 and up.
Still, you will need to request the specific location permissions depending on your use case inside
your app's `AndroidManifest.xml` :

#### Only accessing position through Location Buttons
Whatever version of Android you wish to support (as long as you are targeting SDK 37 and up), you
can simply add those entries to your manifest:
```xml
<uses-permission
    android:name="android.permission.ACCESS_FINE_LOCATION"
    android:usesPermissionFlags="onlyForLocationButton"
    tools:targetApi="37" />

<uses-permission
    android:name="android.permission.ACCESS_COARSE_LOCATION"
    android:maxSdkVersion="36" />
```

The first permission means that you will _only_ be able to access the user's precise location. When
the app runs on Android 17+, the permission can only be granted through the Location Button.

The second permission is **highly** recommended, you can find more information
[here](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime#approximate-request).

#### Mixing usage of the Location Button and regular geolocation APIs
If your app has, for example, a QOL feature that requires one-time access to geolocation and another
optional feature that requires the usual geolocation permission, you can still use the Location
Button.

The following lines **must** be added the manifest to use the button and request the precise
location:
```xml
<uses-permission
    android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission
    android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Again, the second permission is very important, find more information
[here](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime#approximate-request).

> [!NOTE]
> The value of the Location Button is diminished as you will need to declare the same permissions in
> the manifest as if you didn't implement it, excepted the Location Button permission itself.

### Flutter setup
To add a Location Button to your Flutter app, use the `LocationButton` widget.

The widget displays the button through a `PlatformView` when supported, which might look less
"integrated" than the Flutter-rendered widget. Some focus actions may look subpar and matrix
transformation is not supported.

For those reasons, we recommend keeping the button in a place that is either not in a scrollable
widget or far from the scrolling edges (as view deformation animations won't render correctly).

Different overlays won't work as the button actually renders on top of the finalized Flutter frame.
So, no dialog should be opened on top of a Location Button, and back page transitions may look janky
(and thus should be avoided or minimized).

To use the widget, follow the instructions:

1. Add the dependency to your project:
    ```shell
    flutter pub add flutter_location_button
    ```

2. Import the package in your Dart file:
    ```dart
    import 'package:flutter_location_button/flutter_location_button.dart';
    ```

3. Add the widget to your tree: (example using the `geolocator` package)
    ```dart
    LocationButton(
      // Alternatively, use the named factories for LocationButtonStyle to match aesthetics 
      // for different Material widget themes.
      style: LocationButtonStyle(
        // Context is required to translate flutter Logical Pixels to Android Display Units.
        context: context,
        height: 48,
        width: 256,
        textType: .nearMyPreciseLocation,
        cornerRadius: 8,
        pressedCornerRadius: 96,
      ),
      onPermissionGranted: () {
        // You can expect location permissions to be granted (may be coarse or exact).
        final latestLocation = await Geolocator.getCurrentPosition(
          locationSettings: .new(accuracy: .best),
        );

        print(
          'Permission granted! $onlyGrantedForSession $latestLocation',
        );
      },
      onPermissionDenied: () {
        print('Permission denied...');
      },
    )
    ```
