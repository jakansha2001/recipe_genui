// The analyzer sees APP_CHECK_DEBUG_TOKEN as unset and calls `debugToken:`
// redundant; it is set at build time with --dart-define.
// ignore_for_file: avoid_redundant_argument_values

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase AI Logic requires App Check. Once activated, firebase_ai attaches
/// App Check tokens to every request by itself — the backend needs no change.
///
/// Debug builds (simulators, emulators, localhost) use the debug providers:
/// each install generates a token on first launch and logs it; register it
/// once in Firebase Console → App Check → Apps → ⋮ → Manage debug tokens.
/// For CI or tests that reinstall the app, pass a registered token from a
/// secret store with `--dart-define=APP_CHECK_DEBUG_TOKEN=...` — never commit
/// one. Release builds use real device attestation; web release needs a
/// reCAPTCHA Enterprise site key via `--dart-define=RECAPTCHA_SITE_KEY=...`.
Future<void> activateAppCheck() {
  const token = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  const debugToken = token == '' ? null : token;
  return FirebaseAppCheck.instance.activate(
    providerApple: kDebugMode
        ? const AppleDebugProvider(debugToken: debugToken)
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider(debugToken: debugToken)
        : const AndroidPlayIntegrityProvider(),
    providerWeb: kDebugMode
        ? WebDebugProvider(debugToken: debugToken)
        : ReCaptchaEnterpriseProvider(
            const String.fromEnvironment('RECAPTCHA_SITE_KEY'),
          ),
  );
}
