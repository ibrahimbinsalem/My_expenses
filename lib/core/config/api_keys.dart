class ApiKeys {
  static const String gemini = String.fromEnvironment(
    'AIzaSyBqC3vnA4s2t_Lh4Oi9JyluRqEgDtiNv70',
    defaultValue: '',
  );

  static bool get hasGeminiKey => gemini.isNotEmpty;
}
