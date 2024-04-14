/// Environment variables and shared app constants.
abstract class Constants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://elhphzsmlycebqfocaib.supabase.co',
  );

  static const String supabaseAnnonKey = String.fromEnvironment(
    'SUPABASE_ANNON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsaHBoenNtbHljZWJxZm9jYWliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTMxMTc5NDMsImV4cCI6MjAyODY5Mzk0M30.KBw3BVyB0TsCeKqtB_lwVWRP9EZa2UwQ5ORdRflxCbY',
  );
}
