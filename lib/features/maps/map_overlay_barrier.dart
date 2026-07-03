import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Keeps buttons/sheets above map platform views on Flutter web.
Widget mapOverlayBarrier(Widget child, {bool enabled = true}) {
  if (!kIsWeb || !enabled) return child;
  return PointerInterceptor(child: child);
}