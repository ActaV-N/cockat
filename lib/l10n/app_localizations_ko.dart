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
}
