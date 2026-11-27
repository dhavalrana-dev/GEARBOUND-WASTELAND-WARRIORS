import 'package:flutter/painting.dart';

/// Colors used by the current prototype UI, plus the spec's design tokens for
/// the production restyle. Keep raw hex values out of feature code.
abstract final class GbColors {
  // Prototype palette (current screens).
  static const ink = Color(0xFF1B2228);
  static const panel = Color(0xFF28333A);
  static const cream = Color(0xFFF2E4C9);
  static const amber = Color(0xFFFFA84A);

  // Production palette from the specification (not yet applied).
  static const deepSteel = Color(0xFF192531);
  static const gunmetal = Color(0xFF344657);
  static const brass = Color(0xFFD6AC63);
  static const energyYellow = Color(0xFFF4BF4F);
  static const technologyCyan = Color(0xFF35A7B5);
  static const friendlyGreen = Color(0xFF63B77B);
  static const enemyRed = Color(0xFFD65760);
  static const specialPurple = Color(0xFF9B73D0);
}
