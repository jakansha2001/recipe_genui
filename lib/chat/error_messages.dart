/// Turns a failed model request into a message the user can act on. The raw
/// error is kept separately for debugging.
String describeError(Object error) {
  final text = error.toString();
  bool mentions(List<String> needles) => needles.any(text.contains);

  if (mentions(['quota', 'RESOURCE_EXHAUSTED', 'rate limit', '429'])) {
    return 'Sage is getting a lot of requests right now. Give it a minute '
        'and try again.';
  }
  if (mentions(['App Check', 'app_check', 'attestation'])) {
    return "This device isn't verified with Firebase App Check, so Sage "
        "can't reach the model. Register its debug token and try again.";
  }
  if (mentions(['SocketException', 'Failed host lookup', 'network'])) {
    return "Sage can't reach the internet. Check your connection and try "
        'again.';
  }
  return 'Something went wrong. Please try again.';
}
