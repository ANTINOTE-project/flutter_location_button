import 'package:flutter/material.dart';
import 'package:flutter_location_button/flutter_location_button.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Position? latestLocation;

  Future<void> onPermissionGranted(bool onlyGrantedForSession) async {
    latestLocation = await Geolocator.getCurrentPosition(
      locationSettings: .new(accuracy: .best),
    );
    if (mounted) {
      setState(() {});
    }

    print(
      'Permission granted! $onlyGrantedForSession ${latestLocation == null}',
    );
  }

  void onPermissionDenied() {
    print('Permission denied...');
  }

  @override
  Widget build(BuildContext context) {
    final style = LocationButtonStyle.outline(
      context,
      size: .small,
      shape: .round,
      textType: .usePreciseLocation,
      width: 300,
    );
    final smallStyle = LocationButtonStyle.outline(
      context,
      width: 48,
      textType: .none,
      size: .small,
      shape: .round,
    );

    return MaterialApp(
      home: Scaffold(
        body: OverscrollProvider(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .center,
              children: [
                SizedBox(height: 500, width: double.infinity),

                Text('Locally rendered:'),
                Row(
                  children: [
                    LocationButton(
                      style: style,
                      onPermissionGranted: onPermissionGranted,
                      onPermissionDenied: onPermissionDenied,
                      renderingStrategy: .never,
                    ),
                    LocationButton(
                      style: smallStyle,
                      onPermissionGranted: onPermissionGranted,
                      onPermissionDenied: onPermissionDenied,
                      renderingStrategy: .never,
                    ),
                  ],
                ),

                Text('Natively rendered (when safe):'),
                Row(
                  children: [
                    LocationButton(
                      style: style,
                      onPermissionGranted: onPermissionGranted,
                      onPermissionDenied: onPermissionDenied,
                    ),
                    LocationButton(
                      style: smallStyle,
                      onPermissionGranted: onPermissionGranted,
                      onPermissionDenied: onPermissionDenied,
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Text(
                  'Latest position: ${latestLocation == null ? 'undetermined' : (latestLocation!.latitude + latestLocation!.longitude + latestLocation!.altitude).toStringAsFixed(2)} (lat+lon+alt)',
                  textAlign: .center,
                ),
                Builder(
                  builder: (context) {
                    return FilledButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(title: Text('Test dialog'));
                          },
                        );
                      },
                      child: Text('Open dialog'),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    return FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Scaffold(body: Center(child: Text('New page'))),
                          ),
                        );
                      },
                      child: Text('New page'),
                    );
                  },
                ),
                SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
