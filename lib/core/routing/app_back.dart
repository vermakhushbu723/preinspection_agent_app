import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back navigation that always goes *somewhere*.
///
/// Most of the flow moves forward with `context.go`, which replaces the
/// stack instead of growing it. On those screens `Navigator.maybePop()` has
/// nothing to pop, so the back arrow silently did nothing -- and where a
/// stray push *did* exist it unwound all the way out to the login screen,
/// which read as "back karne pe logout ho gaya".
///
/// So: pop when there genuinely is a previous screen, otherwise navigate to
/// the step that precedes this one in the flow.
void appBack(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
