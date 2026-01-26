// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '오늘 뭐 마시지?';

  @override
  String get home => '홈';

  @override
  String get myIngredients => '내 재료';

  @override
  String get cocktails => '칵테일';

  @override
  String get settings => '설정';

  @override
  String get search => '검색';

  @override
  String get searchIngredients => '재료 검색...';

  @override
  String get searchCocktails => '칵테일 검색...';

  @override
  String get noIngredientsSelected => '선택된 재료 없음';

  @override
  String get selectIngredientsPrompt => '가지고 있는 재료를 선택하면 만들 수 있는 칵테일을 찾아드릴게요!';

  @override
  String get canMake => '만들 수 있어요';

  @override
  String get almostCanMake => '거의 다 됐어요';

  @override
  String get oneMoreIngredient => '재료 1개만 더 있으면';

  @override
  String nMoreIngredients(int count) {
    return '재료 $count개만 더 있으면';
  }

  @override
  String get ingredients => '재료';

  @override
  String get instructions => '만드는 법';

  @override
  String get garnish => '가니쉬';

  @override
  String get glass => '글라스';

  @override
  String get method => '기법';

  @override
  String get optional => '선택사항';

  @override
  String substitute(String ingredient) {
    return '대체 가능: $ingredient';
  }

  @override
  String abv(double percent) {
    return '도수: $percent%';
  }

  @override
  String get allIngredients => '전체 재료';

  @override
  String get spirits => '증류주';

  @override
  String get liqueurs => '리큐르';

  @override
  String get wines => '와인 & 강화와인';

  @override
  String get bitters => '비터스';

  @override
  String get juices => '주스';

  @override
  String get syrups => '시럽';

  @override
  String get other => '기타';

  @override
  String get clearAll => '전체 해제';

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String cocktailsFound(int count) {
    return '$count개의 칵테일';
  }

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get darkMode => '다크 모드';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get systemMode => '시스템 설정';

  @override
  String get about => '앱 정보';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get myBar => '내 술장';

  @override
  String get searchProducts => '상품 검색...';

  @override
  String get noProductsSelected => '선택된 상품 없음';

  @override
  String get selectProductsPrompt => '보유한 술병을 추가하면 만들 수 있는 칵테일을 찾아드릴게요!';

  @override
  String get addProduct => '상품 추가';

  @override
  String productsSelected(int count) {
    return '$count병';
  }

  @override
  String get emptyBar => '술장이 비어있어요';

  @override
  String get emptyBarPrompt => '보유한 술병을 추가해보세요';

  @override
  String get brand => '브랜드';

  @override
  String get volume => '용량';

  @override
  String mapsTo(String ingredient) {
    return '종류: $ingredient';
  }

  @override
  String get noProductsAvailable => '아직 등록된 상품이 없어요';

  @override
  String get fallbackToIngredients => '재료 종류로 선택하기';

  @override
  String get allCocktails => '전체 칵테일';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get addedToFavorites => '즐겨찾기에 추가됨';

  @override
  String get removedFromFavorites => '즐겨찾기에서 제거됨';

  @override
  String favoritesLimitReached(int max) {
    return '즐겨찾기가 가득 찼어요 ($max개). 회원가입하면 무제한으로 저장할 수 있어요!';
  }

  @override
  String favoritesCount(int count) {
    return '즐겨찾기 $count개';
  }

  @override
  String get noFavorites => '즐겨찾기가 없어요';

  @override
  String get noFavoritesPrompt => '칵테일의 하트 아이콘을 눌러 즐겨찾기에 추가하세요';

  @override
  String get signUpForMore => '회원가입하고 더 이용하기';

  @override
  String get login => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get logout => '로그아웃';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get resetPassword => '비밀번호 재설정';

  @override
  String get sendResetLink => '재설정 링크 보내기';

  @override
  String get resetLinkSent => '비밀번호 재설정 링크가 이메일로 전송되었습니다';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get orContinueWith => '또는';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요?';

  @override
  String get dontHaveAccount => '계정이 없으신가요?';

  @override
  String get welcomeBack => '다시 만나서 반가워요';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get loginSubtitle => '로그인하면 여러 기기에서 데이터를 동기화할 수 있어요';

  @override
  String get signUpSubtitle => '회원가입하고 무제한 즐겨찾기와 더 많은 기능을 이용하세요';

  @override
  String get passwordMinLength => '비밀번호는 최소 6자 이상이어야 합니다';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get invalidEmail => '유효한 이메일을 입력해주세요';

  @override
  String get fieldRequired => '필수 입력 항목입니다';

  @override
  String get loginSuccess => '로그인되었습니다';

  @override
  String get signUpSuccess => '계정이 생성되었습니다! 이메일을 확인해주세요.';

  @override
  String get logoutSuccess => '로그아웃되었습니다';

  @override
  String get account => '계정';

  @override
  String get notLoggedIn => '로그인되지 않음';

  @override
  String get loginPrompt => '로그인하고 술장과 즐겨찾기를 동기화하세요';

  @override
  String get syncData => '데이터 동기화';

  @override
  String get dataSynced => '데이터가 동기화되었습니다';

  @override
  String get comingSoon => '곧 출시 예정!';

  @override
  String get featureComingSoon => '이 기능은 곧 추가될 예정이에요';

  @override
  String get migrationTitle => '환영합니다!';

  @override
  String get migrationPrompt => '기존에 저장해둔 데이터를 계정에 연결할까요?';

  @override
  String migrationProducts(Object count) {
    return '선택한 상품: $count개';
  }

  @override
  String migrationIngredients(Object count) {
    return '선택한 재료: $count개';
  }

  @override
  String migrationFavorites(Object count) {
    return '즐겨찾기: $count개';
  }

  @override
  String get syncNow => '연결하기';

  @override
  String get skipSync => '건너뛰기';

  @override
  String migrationSuccess(Object count) {
    return '$count개 항목이 계정에 동기화되었습니다';
  }

  @override
  String get migrationFailed => '동기화에 실패했습니다. 나중에 다시 시도해주세요.';

  @override
  String get noResultsFound => '검색 결과가 없어요';

  @override
  String get tryDifferentSearch => '다른 검색어를 시도해보세요';

  @override
  String get products => '상품';

  @override
  String get myBarEmpty => '술장이 비어있어요';

  @override
  String get myBarEmptyPrompt => '상품 탭에서 보유한 술을 추가하면 만들 수 있는 칵테일을 찾아드릴게요';

  @override
  String get goToProducts => '상품 둘러보기';

  @override
  String ownedProducts(int count) {
    return '$count병 보유 중';
  }

  @override
  String get onboardingWelcome => 'Cockat에 오신 것을 환영해요';

  @override
  String get onboardingWelcomeSubtitle => '나만의 칵테일 도우미';

  @override
  String get onboardingProductsTitle => '어떤 술이 있나요?';

  @override
  String get onboardingProductsSubtitle => '집에 있는 술병을 선택해주세요';

  @override
  String get onboardingMiscTitle => '기타 재료';

  @override
  String get onboardingMiscSubtitle => '얼음, 가니쉬, 신선한 재료를 선택해주세요';

  @override
  String get onboardingPreferencesTitle => '설정';

  @override
  String get onboardingPreferencesSubtitle => '선호하는 계량 단위를 선택해주세요';

  @override
  String get onboardingAuthTitle => '진행상황 저장하기';

  @override
  String get onboardingAuthSubtitle => '로그인하면 여러 기기에서 동기화할 수 있어요';

  @override
  String get next => '다음';

  @override
  String get skip => '건너뛰기';

  @override
  String get getStarted => '시작하기';

  @override
  String get browseNow => '둘러보기';

  @override
  String get maybeLater => '나중에';

  @override
  String get unitMl => '밀리리터 (ml)';

  @override
  String get unitOz => '온스 (oz)';

  @override
  String get unitParts => '비율';

  @override
  String get ice => '얼음';

  @override
  String get fresh => '신선한 재료';

  @override
  String get dairy => '유제품';

  @override
  String get mixer => '믹서';

  @override
  String get syrup => '시럽';

  @override
  String get reRunSetup => '초기 설정 다시하기';

  @override
  String get reRunSetupDescription => '처음 설정을 다시 진행합니다';

  @override
  String get setupReset => '설정이 초기화되었습니다';

  @override
  String itemsSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get profile => '프로필';

  @override
  String get guestUser => '게스트';

  @override
  String get signInForMore => '로그인하고 더 많은 기능을 이용하세요';

  @override
  String get benefitSync => '여러 기기에서 동기화';

  @override
  String get benefitFavorites => '무제한 즐겨찾기';

  @override
  String get benefitBackup => '내 술장 백업';

  @override
  String get allSet => '준비 완료!';

  @override
  String get dataSyncMessage => '데이터가 여러 기기에서 동기화됩니다';

  @override
  String signUpSyncPrompt(int count) {
    return '회원가입하면 선택한 $count개 항목을 연동할 수 있어요!';
  }

  @override
  String get loginClearDataNote => '로그인하면 기존에 선택한 항목은 계정 데이터로 대체됩니다';

  @override
  String get general => '일반';

  @override
  String get ingredientSettings => '재료 설정';

  @override
  String get dataManagement => '데이터 관리';

  @override
  String get otherIngredients => '기타 재료';

  @override
  String get otherIngredientsDescription => '얼음, 가니시, 믹서 등을 관리합니다';

  @override
  String get unitSettings => '단위 설정';

  @override
  String get unitSettingsDescription => '레시피 측정 단위를 선택합니다';

  @override
  String get resetSetupConfirm => '초기 설정을 다시 시작합니다. 선택한 항목이 초기화됩니다. 계속하시겠습니까?';

  @override
  String unitChanged(String unit) {
    return '단위가 $unit로 변경되었습니다';
  }

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get mdsPick => 'MD\'s Pick';

  @override
  String get viewAll => '더보기';

  @override
  String get myBarProducts => '내 술장 보유';

  @override
  String get availableSubstitutes => '사용 가능한 대체재';

  @override
  String get ingredientNotOwned => '이 재료를 보유하고 있지 않습니다';

  @override
  String ingredientTypes(int count) {
    return '$count개 종류';
  }

  @override
  String productCount(int count) {
    return '$count개 상품';
  }

  @override
  String get description => '설명';

  @override
  String get country => '원산지';

  @override
  String get alcoholContent => '도수';

  @override
  String get ingredientType => '재료 종류';

  @override
  String get addToMyBar => '내 술장에 추가';

  @override
  String get removeFromMyBar => '내 술장에서 제거';

  @override
  String removeProductConfirm(String name) {
    return '$name을(를) 내 술장에서 제거할까요?';
  }

  @override
  String get remove => '제거';

  @override
  String get productNotFound => '상품을 찾을 수 없습니다';

  @override
  String get footerContact => '문의: dltmdwns0721@kakao.com';

  @override
  String get footerCopyright => '© 2026 Cockat';
}
