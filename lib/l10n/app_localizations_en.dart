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

  @override
  String get myBar => 'My Bar';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get noProductsSelected => 'No products selected';

  @override
  String get selectProductsPrompt =>
      'Add the bottles you have to find cocktails you can make!';

  @override
  String get addProduct => 'Add Product';

  @override
  String productsSelected(int count) {
    return '$count bottles';
  }

  @override
  String get emptyBar => 'Your bar is empty';

  @override
  String get emptyBarPrompt => 'Start by adding the bottles you have';

  @override
  String get brand => 'Brand';

  @override
  String get volume => 'Volume';

  @override
  String mapsTo(String ingredient) {
    return 'Type: $ingredient';
  }

  @override
  String get noProductsAvailable => 'No products available yet';

  @override
  String get fallbackToIngredients => 'Select by ingredient type instead';

  @override
  String get allCocktails => 'All Cocktails';

  @override
  String get favorites => 'Favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String favoritesLimitReached(int max) {
    return 'Favorites limit reached ($max). Sign up for unlimited favorites!';
  }

  @override
  String favoritesCount(int count) {
    return '$count favorites';
  }

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesPrompt =>
      'Tap the heart icon on a cocktail to add it to your favorites';

  @override
  String get signUpForMore => 'Sign up for more';

  @override
  String get login => 'Log In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logout => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Password reset link has been sent to your email';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get loginSubtitle => 'Log in to sync your data across devices';

  @override
  String get signUpSubtitle => 'Sign up for unlimited favorites and more';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get loginSuccess => 'Successfully logged in';

  @override
  String get signUpSuccess =>
      'Account created! Please check your email to verify.';

  @override
  String get logoutSuccess => 'Successfully logged out';

  @override
  String get account => 'Account';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get loginPrompt => 'Log in to sync your bar and favorites';

  @override
  String get syncData => 'Sync Data';

  @override
  String get dataSynced => 'Your data has been synced';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get featureComingSoon => 'This feature is coming soon';

  @override
  String get migrationTitle => 'Welcome!';

  @override
  String get migrationPrompt =>
      'Would you like to sync your saved data to your account?';

  @override
  String migrationProducts(Object count) {
    return 'Products: $count';
  }

  @override
  String migrationIngredients(Object count) {
    return 'Ingredients: $count';
  }

  @override
  String migrationFavorites(Object count) {
    return 'Favorites: $count';
  }

  @override
  String get syncNow => 'Sync Now';

  @override
  String get skipSync => 'Skip';

  @override
  String migrationSuccess(Object count) {
    return 'Synced $count items to your account';
  }

  @override
  String get migrationFailed => 'Sync failed. Please try again later.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get products => 'Products';

  @override
  String get myBarEmpty => 'Your bar is empty';

  @override
  String get myBarEmptyPrompt =>
      'Add products from the Products tab to see what cocktails you can make';

  @override
  String get goToProducts => 'Browse Products';

  @override
  String ownedProducts(int count) {
    return '$count bottles in your bar';
  }

  @override
  String get onboardingWelcome => 'Welcome to Cockat';

  @override
  String get onboardingWelcomeSubtitle => 'Your personal cocktail companion';

  @override
  String get onboardingProductsTitle => 'What\'s in Your Bar?';

  @override
  String get onboardingProductsSubtitle =>
      'Select the bottles you have at home';

  @override
  String get onboardingMiscTitle => 'Other Essentials';

  @override
  String get onboardingMiscSubtitle =>
      'Select ice, garnishes, and fresh ingredients you have';

  @override
  String get onboardingPreferencesTitle => 'Your Preferences';

  @override
  String get onboardingPreferencesSubtitle =>
      'Choose your preferred measurement unit';

  @override
  String get onboardingAuthTitle => 'Save Your Progress';

  @override
  String get onboardingAuthSubtitle =>
      'Sign in to sync your bar across devices';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get browseNow => 'Browse Now';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get unitMl => 'Milliliters (ml)';

  @override
  String get unitOz => 'Ounces (oz)';

  @override
  String get unitParts => 'Parts (ratio)';

  @override
  String get ice => 'Ice';

  @override
  String get fresh => 'Fresh';

  @override
  String get dairy => 'Dairy';

  @override
  String get mixer => 'Mixers';

  @override
  String get syrup => 'Syrups';

  @override
  String get reRunSetup => 'Re-run Setup';

  @override
  String get reRunSetupDescription => 'Go through the initial setup again';

  @override
  String get setupReset => 'Setup has been reset';

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get profile => 'Profile';

  @override
  String get guestUser => 'Guest';

  @override
  String get signInForMore => 'Sign in for more features';

  @override
  String get benefitSync => 'Sync across devices';

  @override
  String get benefitFavorites => 'Unlimited favorites';

  @override
  String get benefitBackup => 'Backup your bar';

  @override
  String get allSet => 'You\'re all set!';

  @override
  String get dataSyncMessage => 'Your data will be synced across devices';

  @override
  String signUpSyncPrompt(int count) {
    return 'Sign up to sync your $count selected items!';
  }

  @override
  String get loginClearDataNote =>
      'Your local selections will be replaced with account data';

  @override
  String get general => 'General';

  @override
  String get ingredientSettings => 'Ingredient Settings';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get otherIngredients => 'Other Ingredients';

  @override
  String get otherIngredientsDescription =>
      'Manage ice, garnishes, mixers, and more';

  @override
  String get unitSettings => 'Unit System';

  @override
  String get unitSettingsDescription => 'Choose measurement units for recipes';

  @override
  String get resetSetupConfirm =>
      'This will restart the setup process. Your selections will be reset. Continue?';

  @override
  String unitChanged(String unit) {
    return 'Unit system changed to $unit';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get mdsPick => 'MD\'s Pick';

  @override
  String get viewAll => 'View All';

  @override
  String get myBarProducts => 'Your Products';

  @override
  String get availableSubstitutes => 'Available Substitutes';

  @override
  String get ingredientNotOwned => 'You don\'t have this ingredient';

  @override
  String ingredientTypes(int count) {
    return '$count types';
  }

  @override
  String productCount(int count) {
    return '$count products';
  }

  @override
  String get description => 'Description';

  @override
  String get country => 'Country';

  @override
  String get alcoholContent => 'ABV';

  @override
  String get ingredientType => 'Ingredient Type';

  @override
  String get addToMyBar => 'Add to My Bar';

  @override
  String get removeFromMyBar => 'Remove from My Bar';

  @override
  String removeProductConfirm(String name) {
    return 'Remove $name from your bar?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get footerContact => 'Contact: liam.leeson5108@gmail.com';

  @override
  String get footerCopyright => '© 2026 Cockat';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmTitle => 'Are you sure?';

  @override
  String get deleteAccountConfirmMessage =>
      'Deleting your account will permanently remove all your data and cannot be undone.';

  @override
  String get deleteAccountSuccess => 'Account deleted successfully';

  @override
  String get delete => 'Delete';

  @override
  String get errorOccurred => 'Oops! Something went wrong';

  @override
  String get somethingWentWrong => 'Please try again later';

  @override
  String get networkError => 'Please check your internet connection';

  @override
  String get timeoutError => 'Request timed out. Please try again';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get myCocktails => 'My Cocktails';

  @override
  String get myCocktailsDescription => 'Create and manage your own recipes';

  @override
  String get createCocktail => 'Create Cocktail';

  @override
  String get editCocktail => 'Edit Cocktail';

  @override
  String get cocktailName => 'Cocktail Name';

  @override
  String get cocktailNameHint => 'e.g., My Signature Martini';

  @override
  String get cocktailDescription => 'Description (optional)';

  @override
  String get cocktailDescriptionHint => 'Describe your cocktail';

  @override
  String get cocktailInstructions => 'Instructions';

  @override
  String get cocktailInstructionsHint =>
      'Write detailed instructions for making this cocktail';

  @override
  String get addIngredient => 'Add Ingredient';

  @override
  String get ingredientName => 'Ingredient Name';

  @override
  String get ingredientAmount => 'Amount';

  @override
  String get ingredientUnit => 'Unit';

  @override
  String get customIngredient => 'Custom';

  @override
  String get customIngredientHint => 'Enter ingredient name';

  @override
  String get searchIngredient => 'Search ingredient...';

  @override
  String get selectIngredient => 'Select Ingredient';

  @override
  String get noUserCocktails => 'No cocktails yet';

  @override
  String get noUserCocktailsPrompt => 'Create your own recipe!';

  @override
  String get saveCocktail => 'Save';

  @override
  String get cocktailSaved => 'Cocktail saved';

  @override
  String get cocktailDeleted => 'Cocktail deleted';

  @override
  String get deleteCocktailConfirm => 'Delete this cocktail?';

  @override
  String get cocktailNameRequired => 'Please enter a cocktail name';

  @override
  String get cocktailInstructionsRequired => 'Please enter instructions';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String myCocktailsCount(int count) {
    return '$count cocktails';
  }

  @override
  String createdAt(String date) {
    return 'Created: $date';
  }
}
