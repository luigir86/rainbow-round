import 'package:flutter/material.dart';

/// The few sizes the screens are made from, the same as Low End's.
abstract final class RoundType {
  static const display = 45.0;
  static const headline = 24.0;
  static const title = 22.0;
  static const body = 16.0;
  static const caption = 14.0;

  /// The smallest text anywhere: nothing is set smaller.
  static const small = 13.0;

  static const textTheme = TextTheme(
    displayMedium: TextStyle(fontSize: display),
    headlineSmall: TextStyle(fontSize: headline),
    titleLarge: TextStyle(fontSize: title),
    titleMedium: TextStyle(fontSize: body),
    titleSmall: TextStyle(fontSize: caption),
    bodyLarge: TextStyle(fontSize: body),
    bodyMedium: TextStyle(fontSize: caption),
    labelLarge: TextStyle(fontSize: caption),
    bodySmall: TextStyle(fontSize: small),
    labelMedium: TextStyle(fontSize: small),
    labelSmall: TextStyle(fontSize: small),
  );
}

/// Shapes and sizes of the controls.
abstract final class RoundShape {
  /// Corner radius of buttons, cards and menus.
  static const radius = 16.0;
}
