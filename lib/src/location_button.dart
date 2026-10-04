import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_location_button/src/location_button_style.dart';
import 'package:flutter_location_button/src/overscroll_provider.dart';
import 'package:flutter_location_button/src/platform_interface/flutter_location_button_api.g.dart';
import 'package:flutter_location_button/src/platform_interface/flutter_location_button_platform_interface.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

extension _StyleToRaw on LocationButtonStyle {
  RawLocationButtonStyle toRaw(double devicePixelRatio) => .new(
    height: (height * devicePixelRatio).floor(),
    width: (width * devicePixelRatio).floor(),
    backgroundColor: backgroundColor?.toARGB32(),
    iconTintColor: iconTintColor?.toARGB32(),
    textColor: textColor?.toARGB32(),
    textType: textType,
    strokeColor: strokeColor?.toARGB32(),
    strokeWidth: (strokeWidth * devicePixelRatio).floor(),
    bottomPadding: (padding.bottom * devicePixelRatio).floor(),
    leftPadding: (padding.left * devicePixelRatio).floor(),
    rightPadding: (padding.right * devicePixelRatio).floor(),
    topPadding: (padding.top * devicePixelRatio).floor(),
    cornerRadius: cornerRadius * devicePixelRatio,
    pressedCornerRadius: pressedCornerRadius * devicePixelRatio,
  );
}

/// Callback used to tell the creator of the widget the necessary permissions
/// were granted to fetch the user's location.
typedef PermissionGrantedCallback = void Function(bool onlyGrantedForSession);

/// Callback used to ask for the broader location permissions when the user taps
/// a locally-rendered button.
typedef PermissionAskCallback = Future<bool> Function();

final _logger = Logger("LocationButton");

/// Different ways the Location Button might be replaced by its locally-rendered
/// counterpart when supported.
enum NativeRenderingStrategy {
  /// Renders the native Location Button when :
  /// - No page transitions are happening
  /// - No modal or other page is placed on top of the widget
  /// - No overscroll is happening
  safe,

  /// Always renders the native Location Button, when supported.
  always,

  /// Never renders the native Location Button.
  never,
}

/// The entrypoint for the Location Button. Place this widget anywhere inside
/// your widget tree and fetch the precise location of the device inside the
/// [onPermissionGranted] callback as you normally would with your usual
/// location package. When [onPermissionGranted] is called, we ensure the
/// permission is granted, and we tell whether the permission was granted only
/// for the session.
///
/// If this widget is inside one or more scroll views and the
/// [renderingStrategy] is set to [NativeRenderingStrategy.safe], we recommend
/// wrapping those inside an [OverscrollProvider] that will tell the widget to
/// stop rendering the native widget when overscroll deformations happen (eg.
/// the Android stretch animation on scroll views).
class const LocationButton({
  super.key,

  /// The style that defines the location button's appearance. Currently,
  /// Display Pixels is the unit we use to size the button, this may change to
  /// use usual Flutter units in the future.
  required final LocationButtonStyle style,

  /// Called when the permission was granted, whether it was upon a
  /// session-based grant (in which case [onlyGrantedForSession] is true) or a
  /// usual permission prompt that grants the permission for the app.
  required final PermissionGrantedCallback onPermissionGranted,

  /// Called when the permission was denied after the user pressed the button.
  /// If the user already had permanently denied the permission, they won't get
  /// any system prompt and this will directly get called.
  final VoidCallback? onPermissionDenied,

  /// Called when non-null and replaces default behavior: asks for location on
  /// Android and errors on other platforms.
  final PermissionAskCallback? askForBroaderPermission,

  /// Defines what button to render explicitly. When
  /// [NativeRenderingStrategy.never], the locally-rendered button is always
  /// rendered. When [NativeRenderingStrategy.always], the native button will
  /// always be rendered, unless the device does not support it. And when
  /// [NativeRenderingStrategy.safe] is used, the native button is supported
  /// when it is in a "stable" state and the device supports the button. This is
  /// the recommended rendering strategy.
  final NativeRenderingStrategy renderingStrategy = .safe,
}) extends StatefulWidget {
  @override
  State<LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends State<LocationButton> with RouteAware {
  int? createdSession;
  Future<int?>? checkFuture;

  late final StreamSubscription<LocationButtonEvent> _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = FlutterLocationButtonPlatform.instance.eventStream.listen(
      onEvent,
      cancelOnError: false,
    );

    if (kDebugMode) {
      _logger.clearListeners();
      _logger.onRecord.listen((event) {
        debugPrint('[${event.level}](${event.loggerName}) ${event.message}');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    checkFuture ??= checkAvailability(MediaQuery.devicePixelRatioOf(context));
  }

  void onEvent(LocationButtonEvent event) {
    if (event.sessionHandle != createdSession) return;

    switch (event) {
      case LocationButtonDeathEvent():
        createdSession = null;
        checkFuture = Future.value(null);

        if (mounted) {
          setState(() {
            /* We set state so that we transition silently to the unsupported
               variant of the button */
          });
        }
    }
  }

  @override
  void dispose() {
    if (createdSession != null) {
      FlutterLocationButtonPlatform.instance.closeSession(createdSession!);
    }

    _subscription.cancel();

    super.dispose();
  }

  final handle = Object();

  Future<int?> checkAvailability(double devicePixelRatio) async {
    final sessionHandle = handle.hashCode;
    if (!(await FlutterLocationButtonPlatform.instance.createSession(
          sessionHandle,
          widget.style.toRaw(devicePixelRatio),
        )) ||
        widget.renderingStrategy == .never) {
      _logger.warning('Failed to create session.');
      return null;
    }

    createdSession = sessionHandle;
    _logger.info('Created session with handle $createdSession');

    return createdSession;
  }

  @override
  void didUpdateWidget(covariant LocationButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldStyle = oldWidget.style;
    final newStyle = widget.style;

    final dpr = MediaQuery.devicePixelRatioOf(context);

    if (createdSession != null) {
      FlutterLocationButtonPlatform.instance.updateButton(
        createdSession!,
        oldStyle.toRaw(dpr),
        newStyle.toRaw(dpr),
      );
    }

    if (widget.renderingStrategy != .never && createdSession == null) {
      setState(() {
        checkFuture = checkAvailability(dpr);
      });
    }
  }

  bool _isWidgetSafe(BuildContext context, bool isOverscrolling) {
    if (isOverscrolling) {
      return false;
    }

    final route = ModalRoute.of(context);

    // Not the highest route.
    if (!(route?.isCurrent ?? true)) return false;

    // During a transition
    if ((route?.animation?.isAnimating ?? false) ||
        (route?.secondaryAnimation?.isAnimating ?? false)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkFuture,
      builder: (context, snapshot) {
        if (widget.renderingStrategy == .safe && snapshot.data != null) {
          return ValueListenableBuilder(
            valueListenable:
                OverscrollProvider.of(context)?.isOverscrolling ??
                ValueNotifier(false),
            builder: (context, value, child) {
              return AnimatedSwitcher(
                duration: .new(milliseconds: 250),
                switchInCurve: Curves.fastOutSlowIn,
                switchOutCurve: Curves.fastOutSlowIn,
                child:
                    (_isWidgetSafe(context, value)
                    ? _SupportedLocationButton.new
                    : _UnsupportedLocationButton.new)(
                      key: widget.key,
                      style: widget.style,
                      sessionHandle: snapshot.requireData!,

                      onPermissionGranted: widget.onPermissionGranted,
                      onPermissionDenied: widget.onPermissionDenied,
                    ),
              );
            },
          );
        }

        if (snapshot.data == null || widget.renderingStrategy == .never) {
          return _UnsupportedLocationButton(
            key: widget.key,
            style: widget.style,
            sessionHandle: handle.hashCode,

            onPermissionGranted: widget.onPermissionGranted,
            onPermissionDenied: widget.onPermissionDenied,
            askForBroaderPermission: widget.askForBroaderPermission,
          );
        }

        return _SupportedLocationButton(
          key: widget.key,
          style: widget.style,
          sessionHandle: snapshot.requireData!,

          onPermissionGranted: widget.onPermissionGranted,
          onPermissionDenied: widget.onPermissionDenied,
        );
      },
    );
  }
}

class const _UnsupportedLocationButton({
  super.key,
  required final int sessionHandle,
  required final LocationButtonStyle style,

  required final PermissionGrantedCallback onPermissionGranted,
  required final VoidCallback? onPermissionDenied,
  required final PermissionAskCallback? askForBroaderPermission,
}) extends StatelessWidget {
  void onPressed() async {
    final result = askForBroaderPermission != null
        ? await askForBroaderPermission!()
        : await FlutterLocationButtonPlatform.instance.askForBroaderPermission(
            sessionHandle,
          );

    if (result) {
      onPermissionGranted(false);
    } else {
      onPermissionDenied?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Symbols.my_location,
      color: style.iconTintColor,
      fontWeight: .bold,
      size: 20,
    );
    final buttonStyle = ButtonStyle(
      fixedSize: .all(
        Size(
          style.width - style.padding.horizontal,
          style.height - style.padding.vertical,
        ),
      ),
      padding: .all(style.padding),
      elevation: .all(0),
      backgroundColor: .all(style.backgroundColor),
      overlayColor: .all(style.textColor?.withAlpha(20)),
      iconColor: .all(style.iconTintColor),
      shape: .fromMap({
        WidgetState.pressed: RoundedRectangleBorder(
          side: .new(
            width: style.strokeWidth,
            color: style.strokeColor ?? Color(0xFF000000),
            style: style.strokeWidth == 0 ? .none : .solid,
          ),
          borderRadius: .circular(style.pressedCornerRadius),
        ),
        WidgetState.any: RoundedRectangleBorder(
          side: .new(
            width: style.strokeWidth,
            color: style.strokeColor ?? Color(0xFF000000),
            style: style.strokeWidth == 0 ? .none : .solid,
          ),
          borderRadius: .circular(style.cornerRadius),
        ),
      }),
    );

    return StreamBuilder(
      stream: FlutterLocationButtonPlatform.instance.localizationStream,
      initialData: FlutterLocationButtonPlatform.instance.localization,
      builder: (context, snapshot) {
        return Container(
          height: style.height,
          width: style.width,
          padding: style.padding,
          child: style.textType == .none
              ? IconButton.outlined(
                  onPressed: onPressed,
                  icon: icon,
                  style: buttonStyle,
                )
              : FilledButton.icon(
                  onPressed: onPressed,
                  icon: icon,
                  style: buttonStyle,
                  label: Text(
                    snapshot.data?[style.textType] ?? '',
                    style: .new(color: style.textColor),
                  ),
                ),
        );
      },
    );
  }
}

class const _SupportedLocationButton({
  super.key,
  required final LocationButtonStyle style,
  required final int sessionHandle,

  required final PermissionGrantedCallback onPermissionGranted,
  required final VoidCallback? onPermissionDenied,
}) extends StatefulWidget {
  @override
  State<_SupportedLocationButton> createState() =>
      _SupportedLocationButtonState();
}

class _SupportedLocationButtonState extends State<_SupportedLocationButton> {
  static const _viewType = 'location_button';

  late final StreamSubscription<LocationButtonEvent> _subscription;

  late final FocusNode node = FocusNode(
    debugLabel: 'location-button-${widget.sessionHandle}',
    canRequestFocus: true,
    skipTraversal: true,
    descendantsAreFocusable: false,
    descendantsAreTraversable: false,
  );

  @override
  void initState() {
    super.initState();

    _subscription = FlutterLocationButtonPlatform.instance.eventStream.listen(
      onEvent,
      cancelOnError: false,
    );
  }

  void onEvent(LocationButtonEvent event) {
    if (event.sessionHandle != widget.sessionHandle) return;

    switch (event) {
      case LocationButtonResultEvent(granted: final granted):
        node.requestFocus();

        if (granted) {
          widget.onPermissionGranted(true);
        } else {
          widget.onPermissionDenied?.call();
        }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: node,
      child: SizedBox(
        height: widget.style.height,
        width: widget.style.width,
        child: PlatformViewLink(
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: .opaque,
              gestureRecognizers: {.new(() => TapGestureRecognizer())},
            );
          },
          onCreatePlatformView: (params) {
            return PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: _viewType,
                layoutDirection: Directionality.maybeOf(context) ?? .ltr,
                creationParams: widget.sessionHandle,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create(size: Size(widget.style.width, widget.style.height));
          },
          viewType: _viewType,
        ),
      ),
    );
  }
}
