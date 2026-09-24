class LicensePlateNormalizer {
  const LicensePlateNormalizer._();

  static String normalize(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}
