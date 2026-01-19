// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'What to Drink?';

  @override
  String get home => 'Home';

  @override
  String get myIngredients => 'My Ingredients';

  @override
  String get cocktails => 'Cocktails';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get searchIngredients => 'Search ingredients...';

  @override
  String get searchCocktails => 'Search cocktails...';

  @override
  String get noIngredientsSelected => 'No ingredients selected';

  @override
  String get selectIngredientsPrompt =>
      'Select the ingredients you have to find cocktails you can make!';

  @override
  String get canMake => 'Can Make';

  @override
  String get almostCanMake => 'Almost There';

  @override
  String get oneMoreIngredient => '1 more ingredient needed';

  @override
  String nMoreIngredients(int count) {
    return '$count more ingredients needed';
  }

  @override
  String get ingredients => 'Ingredients';

  @override
  String get instructions => 'Instructions';

  @override
  String get garnish => 'Garnish';

  @override
  String get glass => 'Glass';

  @override
  String get method => 'Method';

  @override
  String get optional => 'Optional';

  @override
  String substitute(String ingredient) {
    return 'Can substitute with: $ingredient';
  }

  @override
  String abv(double percent) {
    return 'ABV: $percent%';
  }

  @override
  String get allIngredients => 'All Ingredients';

  @override
  String get spirits => 'Spirits';

  @override
  String get liqueurs => 'Liqueurs';

  @override
  String get wines => 'Wines & Fortified';

  @override
  String get bitters => 'Bitters';

  @override
  String get juices => 'Juices';

  @override
  String get syrups => 'Syrups';

  @override
  String get other => 'Other';

  @override
  String get clearAll => 'Clear All';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String cocktailsFound(int count) {
    return '$count cocktails found';
  }

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }
}
