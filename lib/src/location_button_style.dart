import 'dart:math';

import 'package:flutter_location_button/src/platform_interface/flutter_location_button_api.g.dart'
    show LocationButtonTextType;
import 'package:material_ui/material_ui.dart';

export 'platform_interface/flutter_location_button_api.g.dart'
    show LocationButtonTextType;

/// Describes the appearance of the Location Button.
final class LocationButtonStyle {
  new({
    // /// We fetch the display's Device Pixel Ratio to do calculations and make
    // /// the different heights and widths consistent.
    // required BuildContext context,

    /// The height of the button, between 48dp and 136dp (inclusive).
    required double height,

    /// The width of the button, at least 48dp.
    required double width,

    /// The background color. The alpha channel is automatically overridden to
    /// opaque.
    Color? backgroundColor,
    this.iconTintColor,
    this.textColor, // TODO: Shift colors to satisfy contrast constraint.

    required this.textType,

    this.strokeColor,

    /// The thickness of the outline formed around the button. The value ranges
    /// between 0dp and 3dp (inclusive).
    double strokeWidth = 0,

    /// The padding for the button. Sides all range between 4dp and 8dp
    /// (inclusive), the values are clamped if not within.
    EdgeInsets padding = const EdgeInsets.all(4),

    /// Corner radius for the button when it is unpressed. Must be positive.
    double cornerRadius = 6.0,

    /// Corner radius for the button when it is pressed. Must be positive.
    double pressedCornerRadius = 14.0,
  }) {
    // assert(
    //   context.mounted,
    //   'Cannot create a Location Button Style without a mounted '
    //   'context.',
    // );

    // We keep values here as Flutter logical pixels but clamp them relative to
    // the bounds we translate using the Device Pixel Ratio. Translation to the
    // host pixel unit is then done when the style is sent to the platform.

    // This is in lp/dp
    // final iDpr = 1 / MediaQuery.devicePixelRatioOf(context);

    this.height = height.clamp(48, 136);
    this.width = max(48, width);

    this.backgroundColor = backgroundColor?.withValues(alpha: 1);

    this.strokeWidth = strokeWidth.clamp(0, 3);

    // final fourDp = 4 * iDpr;
    // final eightDp = 2 * fourDp;

    this.padding = EdgeInsets.fromLTRB(
      padding.left.clamp(4, 8),
      padding.top.clamp(4, 8),
      padding.right.clamp(4, 8),
      padding.bottom.clamp(4, 8),
    );

    this.cornerRadius = max(0, cornerRadius);
    this.pressedCornerRadius = max(0, pressedCornerRadius);
  }

  factory elevated(
    BuildContext context, {
    required double width,
    required LocationButtonTextType textType,
    required ButtonSizeVariant size,
    required ButtonShapeVariant shape,
  }) {
    return ._fromVariant(
      context,
      width: width,
      textType: textType,
      size: size,
      shape: shape,
      backgroundColor: ColorScheme.of(context).surfaceContainerLow,
      textColor: ColorScheme.of(context).primary,
      iconColor: ColorScheme.of(context).primary,
    );
  }

  factory filled(
    BuildContext context, {
    required double width,
    required LocationButtonTextType textType,
    required ButtonSizeVariant size,
    required ButtonShapeVariant shape,
  }) {
    return ._fromVariant(
      context,
      width: width,
      textType: textType,
      size: size,
      shape: shape,
      backgroundColor: ColorScheme.of(context).primary,
      textColor: ColorScheme.of(context).onPrimary,
      iconColor: ColorScheme.of(context).onPrimary,
    );
  }

  factory tonal(
    BuildContext context, {
    required double width,
    required LocationButtonTextType textType,
    required ButtonSizeVariant size,
    required ButtonShapeVariant shape,
  }) {
    return ._fromVariant(
      context,
      width: width,
      textType: textType,
      size: size,
      shape: shape,
      backgroundColor: ColorScheme.of(context).secondaryContainer,
      textColor: ColorScheme.of(context).onSecondaryContainer,
      iconColor: ColorScheme.of(context).onSecondaryContainer,
    );
  }

  factory outline(
    BuildContext context, {
    required double width,
    required LocationButtonTextType textType,
    required ButtonSizeVariant size,
    required ButtonShapeVariant shape,

    /// Specify this if the background color is incorrect (transparency is not
    /// allowed on this).
    Color? backgroundColor,
  }) {
    return ._fromVariant(
      context,
      width: width,
      textType: textType,
      size: size,
      shape: shape,
      backgroundColor: backgroundColor ?? ColorScheme.of(context).surface,
      textColor: ColorScheme.of(context).onSurfaceVariant,
      iconColor: ColorScheme.of(context).onSurfaceVariant,
      outlineColor: ColorScheme.of(context).outlineVariant,
    );
  }

  factory _fromVariant(
    BuildContext context, {
    required double width,
    required LocationButtonTextType textType,
    required ButtonSizeVariant size,
    required ButtonShapeVariant shape,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? outlineColor,
  }) {
    return .new(
      height: switch (size) {
        .xSmall => 32.0,
        .small => 40.0,
        .medium => 56.0,
        .large => 96.0,
        .xLarge => 136.0,
      },
      width: width,
      textType: textType,
      padding: switch (size) {
        .xSmall => .symmetric(horizontal: 8.0),
        .small || .medium || .large || .xLarge => .symmetric(horizontal: 4.0),
      },
      cornerRadius: switch (shape) {
        .round => switch (size) {
          .xSmall => 16.0,
          .small => 20.0,
          .medium => 28.0,
          .large => 48.0,
          .xLarge => 68.0,
        },
        .square => switch (size) {
          .xSmall => 12.0,
          .small => 12.0,
          .medium => 16.0,
          .large => 28.0,
          .xLarge => 28.0,
        },
      },
      pressedCornerRadius: switch (size) {
        .xSmall => 8.0,
        .small => 8.0,
        .medium => 12.0,
        .large => 16.0,
        .xLarge => 16.0,
      },
      backgroundColor: backgroundColor,
      iconTintColor: iconColor,
      textColor: textColor,
      strokeColor: outlineColor ?? ColorScheme.of(context).outline,
      strokeWidth: switch (size) {
        .xSmall || .small || .medium => 1.0,
        .large => 2.0,
        .xLarge => 3.0,
      },
    );
  }

  /// The height of the button, between 48dp and 136dp (inclusive).
  late final double height;

  /// The width of the button, at least 48dp.
  late final double width;

  /// The background color. The alpha channel is automatically overridden to
  /// opaque.
  late final Color? backgroundColor;

  /// The color for the tint of the icon of the button. The minimum
  /// contrast ratio for the tint is 4.5:1. The system may shift the color of
  /// the icon to satisfy this constraint.
  late final Color? iconTintColor;

  /// The color of the text of the button (if present). The minimum contrast
  /// ratio for the color is 4.5:1. The system may shift the color of the text
  /// to satisfy this constraint.
  late final Color? textColor;

  /// The type of label to display on top of the bottom.
  final LocationButtonTextType textType;

  /// The color of the outline around the button. Defaults to the
  /// [backgroundColor].
  late final Color? strokeColor;

  /// The thickness of the outline formed around the button. The value ranges
  /// between 0dp and 3dp (inclusive).
  late final double strokeWidth;

  /// The padding for the button. Sides all range between 4dp and 8dp
  /// (inclusive), the values are clamped if not within.
  late final EdgeInsets padding;

  /// Corner radius for the button when it is unpressed. Must be positive.
  late final double cornerRadius;

  /// Corner radius for the button when it is pressed. Must be positive.
  late final double pressedCornerRadius;
}
