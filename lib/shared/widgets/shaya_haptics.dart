import 'dart:async';

import 'package:flutter/services.dart';

enum ShayaHapticType { selection, light, medium }

class ShayaHaptics {
  const ShayaHaptics._();

  static void trigger(ShayaHapticType type) {
    switch (type) {
      case ShayaHapticType.selection:
        unawaited(HapticFeedback.selectionClick());
      case ShayaHapticType.light:
        unawaited(HapticFeedback.lightImpact());
      case ShayaHapticType.medium:
        unawaited(HapticFeedback.mediumImpact());
    }
  }
}
