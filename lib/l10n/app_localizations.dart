import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'What to Drink?'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myIngredients.
  ///
  /// In en, this message translates to:
  /// **'My Ingredients'**
  String get myIngredients;

  /// No description provided for @cocktails.
  ///
  /// In en, this message translates to:
  /// **'Cocktails'**
  String get cocktails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchIngredients.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get searchIngredients;

  /// No description provided for @searchCocktails.
  ///
  /// In en, this message translates to:
  /// **'Search cocktails...'**
  String get searchCocktails;

  /// No description provided for @noIngredientsSelected.
  ///
  /// In en, this message translates to:
  /// **'No ingredients selected'**
  String get noIngredientsSelected;

  /// No description provided for @selectIngredientsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select the ingredients you have to find cocktails you can make!'**
  String get selectIngredientsPrompt;

  /// No description provided for @canMake.
  ///
  /// In en, this message translates to:
  /// **'Can Make'**
  String get canMake;

  /// No description provided for @almostCanMake.
  ///
  /// In en, this message translates to:
  /// **'Almost There'**
  String get almostCanMake;

  /// No description provided for @oneMoreIngredient.
  ///
  /// In en, this message translates to:
  /// **'1 more ingredient needed'**
  String get oneMoreIngredient;

  /// No description provided for @nMoreIngredients.
  ///
  /// In en, this message translates to:
  /// **'{count} more ingredients needed'**
  String nMoreIngredients(int count);

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @garnish.
  ///
  /// In en, this message translates to:
  /// **'Garnish'**
  String get garnish;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glass;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @substitute.
  ///
  /// In en, this message translates to:
  /// **'Can substitute with: {ingredient}'**
  String substitute(String ingredient);

  /// No description provided for @abv.
  ///
  /// In en, this message translates to:
  /// **'ABV: {percent}%'**
  String abv(double percent);

  /// No description provided for @allIngredients.
  ///
  /// In en, this message translates to:
  /// **'All Ingredients'**
  String get allIngredients;

  /// No description provided for @spirits.
  ///
  /// In en, this message translates to:
  /// **'Spirits'**
  String get spirits;

  /// No description provided for @liqueurs.
  ///
  /// In en, this message translates to:
  /// **'Liqueurs'**
  String get liqueurs;

  /// No description provided for @wines.
  ///
  /// In en, this message translates to:
  /// **'Wines & Fortified'**
  String get wines;

  /// No description provided for @bitters.
  ///
  /// In en, this message translates to:
  /// **'Bitters'**
  String get bitters;

  /// No description provided for @juices.
  ///
  /// In en, this message translates to:
  /// **'Juices'**
  String get juices;

  /// No description provided for @syrups.
  ///
  /// In en, this message translates to:
  /// **'Syrups'**
  String get syrups;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @cocktailsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} cocktails found'**
  String cocktailsFound(int count);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @myBar.
  ///
  /// In en, this message translates to:
  /// **'My Bar'**
  String get myBar;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noProductsSelected.
  ///
  /// In en, this message translates to:
  /// **'No products selected'**
  String get noProductsSelected;

  /// No description provided for @selectProductsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add the bottles you have to find cocktails you can make!'**
  String get selectProductsPrompt;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @productsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} bottles'**
  String productsSelected(int count);

  /// No description provided for @emptyBar.
  ///
  /// In en, this message translates to:
  /// **'Your bar is empty'**
  String get emptyBar;

  /// No description provided for @emptyBarPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start by adding the bottles you have'**
  String get emptyBarPrompt;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @mapsTo.
  ///
  /// In en, this message translates to:
  /// **'Type: {ingredient}'**
  String mapsTo(String ingredient);

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available yet'**
  String get noProductsAvailable;

  /// No description provided for @fallbackToIngredients.
  ///
  /// In en, this message translates to:
  /// **'Select by ingredient type instead'**
  String get fallbackToIngredients;

  /// No description provided for @allCocktails.
  ///
  /// In en, this message translates to:
  /// **'All Cocktails'**
  String get allCocktails;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @favoritesLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Favorites limit reached ({max}). Sign up for unlimited favorites!'**
  String favoritesLimitReached(int max);

  /// No description provided for @favoritesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} favorites'**
  String favoritesCount(int count);

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on a cocktail to add it to your favorites'**
  String get noFavoritesPrompt;

  /// No description provided for @signUpForMore.
  ///
  /// In en, this message translates to:
  /// **'Sign up for more'**
  String get signUpForMore;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email'**
  String get resetLinkSent;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to sync your data across devices'**
  String get loginSubtitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up for unlimited favorites and more'**
  String get signUpSubtitle;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in'**
  String get loginSuccess;

  /// No description provided for @signUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to verify.'**
  String get signUpSuccess;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out'**
  String get logoutSuccess;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to sync your bar and favorites'**
  String get loginPrompt;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @dataSynced.
  ///
  /// In en, this message translates to:
  /// **'Your data has been synced'**
  String get dataSynced;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get featureComingSoon;

  /// No description provided for @migrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get migrationTitle;

  /// No description provided for @migrationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to sync your saved data to your account?'**
  String get migrationPrompt;

  /// No description provided for @migrationProducts.
  ///
  /// In en, this message translates to:
  /// **'Products: {count}'**
  String migrationProducts(Object count);

  /// No description provided for @migrationIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients: {count}'**
  String migrationIngredients(Object count);

  /// No description provided for @migrationFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites: {count}'**
  String migrationFavorites(Object count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @skipSync.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipSync;

  /// No description provided for @migrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} items to your account'**
  String migrationSuccess(Object count);

  /// No description provided for @migrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again later.'**
  String get migrationFailed;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @myBarEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bar is empty'**
  String get myBarEmpty;

  /// No description provided for @myBarEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add products from the Products tab to see what cocktails you can make'**
  String get myBarEmptyPrompt;

  /// No description provided for @goToProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get goToProducts;

  /// No description provided for @ownedProducts.
  ///
  /// In en, this message translates to:
  /// **'{count} bottles in your bar'**
  String ownedProducts(int count);

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Cockat'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal cocktail companion'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s in Your Bar?'**
  String get onboardingProductsTitle;

  /// No description provided for @onboardingProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the bottles you have at home'**
  String get onboardingProductsSubtitle;

  /// No description provided for @onboardingMiscTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Essentials'**
  String get onboardingMiscTitle;

  /// No description provided for @onboardingMiscSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select ice, garnishes, and fresh ingredients you have'**
  String get onboardingMiscSubtitle;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred measurement unit'**
  String get onboardingPreferencesSubtitle;

  /// No description provided for @onboardingAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Your Progress'**
  String get onboardingAuthTitle;

  /// No description provided for @onboardingAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your bar across devices'**
  String get onboardingAuthSubtitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @browseNow.
  ///
  /// In en, this message translates to:
  /// **'Browse Now'**
  String get browseNow;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'Milliliters (ml)'**
  String get unitMl;

  /// No description provided for @unitOz.
  ///
  /// In en, this message translates to:
  /// **'Ounces (oz)'**
  String get unitOz;

  /// No description provided for @unitParts.
  ///
  /// In en, this message translates to:
  /// **'Parts (ratio)'**
  String get unitParts;

  /// No description provided for @ice.
  ///
  /// In en, this message translates to:
  /// **'Ice'**
  String get ice;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @dairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get dairy;

  /// No description provided for @mixer.
  ///
  /// In en, this message translates to:
  /// **'Mixers'**
  String get mixer;

  /// No description provided for @syrup.
  ///
  /// In en, this message translates to:
  /// **'Syrups'**
  String get syrup;

  /// No description provided for @reRunSetup.
  ///
  /// In en, this message translates to:
  /// **'Re-run Setup'**
  String get reRunSetup;

  /// No description provided for @reRunSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Go through the initial setup again'**
  String get reRunSetupDescription;

  /// No description provided for @setupReset.
  ///
  /// In en, this message translates to:
  /// **'Setup has been reset'**
  String get setupReset;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String itemsSelected(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// No description provided for @signInForMore.
  ///
  /// In en, this message translates to:
  /// **'Sign in for more features'**
  String get signInForMore;

  /// No description provided for @benefitSync.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get benefitSync;

  /// No description provided for @benefitFavorites.
  ///
  /// In en, this message translates to:
  /// **'Unlimited favorites'**
  String get benefitFavorites;

  /// No description provided for @benefitBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup your bar'**
  String get benefitBackup;

  /// No description provided for @allSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get allSet;

  /// No description provided for @dataSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data will be synced across devices'**
  String get dataSyncMessage;

  /// No description provided for @signUpSyncPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign up to sync your {count} selected items!'**
  String signUpSyncPrompt(int count);

  /// No description provided for @loginClearDataNote.
  ///
  /// In en, this message translates to:
  /// **'Your local selections will be replaced with account data'**
  String get loginClearDataNote;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @ingredientSettings.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Settings'**
  String get ingredientSettings;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @otherIngredients.
  ///
  /// In en, this message translates to:
  /// **'Other Ingredients'**
  String get otherIngredients;

  /// No description provided for @otherIngredientsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage ice, garnishes, mixers, and more'**
  String get otherIngredientsDescription;

  /// No description provided for @unitSettings.
  ///
  /// In en, this message translates to:
  /// **'Unit System'**
  String get unitSettings;

  /// No description provided for @unitSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose measurement units for recipes'**
  String get unitSettingsDescription;

  /// No description provided for @resetSetupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will restart the setup process. Your selections will be reset. Continue?'**
  String get resetSetupConfirm;

  /// No description provided for @unitChanged.
  ///
  /// In en, this message translates to:
  /// **'Unit system changed to {unit}'**
  String unitChanged(String unit);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @mdsPick.
  ///
  /// In en, this message translates to:
  /// **'MD\'s Pick'**
  String get mdsPick;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @myBarProducts.
  ///
  /// In en, this message translates to:
  /// **'Your Products'**
  String get myBarProducts;

  /// No description provided for @availableSubstitutes.
  ///
  /// In en, this message translates to:
  /// **'Available Substitutes'**
  String get availableSubstitutes;

  /// No description provided for @ingredientNotOwned.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have this ingredient'**
  String get ingredientNotOwned;

  /// No description provided for @ingredientTypes.
  ///
  /// In en, this message translates to:
  /// **'{count} types'**
  String ingredientTypes(int count);

  /// No description provided for @productCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productCount(int count);

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @alcoholContent.
  ///
  /// In en, this message translates to:
  /// **'ABV'**
  String get alcoholContent;

  /// No description provided for @ingredientType.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Type'**
  String get ingredientType;

  /// No description provided for @addToMyBar.
  ///
  /// In en, this message translates to:
  /// **'Add to My Bar'**
  String get addToMyBar;

  /// No description provided for @removeFromMyBar.
  ///
  /// In en, this message translates to:
  /// **'Remove from My Bar'**
  String get removeFromMyBar;

  /// No description provided for @removeProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your bar?'**
  String removeProductConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @footerContact.
  ///
  /// In en, this message translates to:
  /// **'Contact: liam.leeson5108@gmail.com'**
  String get footerContact;

  /// No description provided for @footerCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Cockat'**
  String get footerCopyright;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all your data and cannot be undone.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get deleteAccountSuccess;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get errorOccurred;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get somethingWentWrong;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get networkError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again'**
  String get timeoutError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @myCocktails.
  ///
  /// In en, this message translates to:
  /// **'My Cocktails'**
  String get myCocktails;

  /// No description provided for @myCocktailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your own recipes'**
  String get myCocktailsDescription;

  /// No description provided for @createCocktail.
  ///
  /// In en, this message translates to:
  /// **'Create Cocktail'**
  String get createCocktail;

  /// No description provided for @editCocktail.
  ///
  /// In en, this message translates to:
  /// **'Edit Cocktail'**
  String get editCocktail;

  /// No description provided for @cocktailName.
  ///
  /// In en, this message translates to:
  /// **'Cocktail Name'**
  String get cocktailName;

  /// No description provided for @cocktailNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Signature Martini'**
  String get cocktailNameHint;

  /// No description provided for @cocktailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get cocktailDescription;

  /// No description provided for @cocktailDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your cocktail'**
  String get cocktailDescriptionHint;

  /// No description provided for @cocktailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get cocktailInstructions;

  /// No description provided for @cocktailInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Write detailed instructions for making this cocktail'**
  String get cocktailInstructionsHint;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @ingredientName.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Name'**
  String get ingredientName;

  /// No description provided for @ingredientAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ingredientAmount;

  /// No description provided for @ingredientUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get ingredientUnit;

  /// No description provided for @customIngredient.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customIngredient;

  /// No description provided for @customIngredientHint.
  ///
  /// In en, this message translates to:
  /// **'Enter ingredient name'**
  String get customIngredientHint;

  /// No description provided for @searchIngredient.
  ///
  /// In en, this message translates to:
  /// **'Search ingredient...'**
  String get searchIngredient;

  /// No description provided for @selectIngredient.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient'**
  String get selectIngredient;

  /// No description provided for @noUserCocktails.
  ///
  /// In en, this message translates to:
  /// **'No cocktails yet'**
  String get noUserCocktails;

  /// No description provided for @noUserCocktailsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your own recipe!'**
  String get noUserCocktailsPrompt;

  /// No description provided for @saveCocktail.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveCocktail;

  /// No description provided for @cocktailSaved.
  ///
  /// In en, this message translates to:
  /// **'Cocktail saved'**
  String get cocktailSaved;

  /// No description provided for @cocktailDeleted.
  ///
  /// In en, this message translates to:
  /// **'Cocktail deleted'**
  String get cocktailDeleted;

  /// No description provided for @deleteCocktailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this cocktail?'**
  String get deleteCocktailConfirm;

  /// No description provided for @cocktailNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a cocktail name'**
  String get cocktailNameRequired;

  /// No description provided for @cocktailInstructionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter instructions'**
  String get cocktailInstructionsRequired;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @myCocktailsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cocktails'**
  String myCocktailsCount(int count);

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdAt(String date);

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your ideas and suggestions'**
  String get sendFeedbackSubtitle;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback'**
  String get feedbackLoadError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
