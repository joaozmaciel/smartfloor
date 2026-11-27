const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

void ensureConfigured() {
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY e execute '
      'flutter run --dart-define-from-file=env.json.',
    );
  }
}
