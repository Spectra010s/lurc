/// Centralized asset paths so you never hardcode strings in widgets.
///
/// Add new assets here as you add them to the assets/ folder.
class AppAssets {
  AppAssets._();

  static const _imagesPath = 'assets/images';
  static const _iconsPath = 'assets/icons';
  static const _animationsPath = 'assets/animations';
  static const _translationsPath = 'assets/translations';

   // ignore: unused_field, reason: kept for symmetry with other paths; will be used when fonts are referenced from code
  static const _fontsPath = 'assets/fonts';

  // Images
  static const String placeholderImage = '$_imagesPath/placeholder.png';

  // Icons
  static const String placeholderIcon = '$_iconsPath/placeholder.svg';

  // Animations
  static const String placeholderAnimation =
      '$_animationsPath/placeholder.json';

  // Translations
  static const String enTranslations = '$_translationsPath/en.json';
}
