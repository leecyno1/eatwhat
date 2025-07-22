import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 应用本地化类
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 简体中文
    Locale('en', 'US'), // 英语
    Locale('ja', 'JP'), // 日语
    Locale('ko', 'KR'), // 韩语
  ];

  // 应用基础文案
  String get appName => _getText('app_name');
  String get welcomeTitle => _getText('welcome_title');
  String get welcomeSubtitle => _getText('welcome_subtitle');

  // 气泡交互相关
  String get bubbleScreenTitle => _getText('bubble_screen_title');
  String get bubbleScreenSubtitle => _getText('bubble_screen_subtitle');
  String get selectedBubbles => _getText('selected_bubbles');
  String get clearSelection => _getText('clear_selection');
  String get generateRecommendations => _getText('generate_recommendations');

  // 推荐相关
  String get recommendationsTitle => _getText('recommendations_title');
  String get noRecommendations => _getText('no_recommendations');
  String get aiRecommendation => _getText('ai_recommendation');
  String get matchScore => _getText('match_score');

  // 用户操作提示
  String get tapToSelect => _getText('tap_to_select');
  String get swipeUpToLike => _getText('swipe_up_to_like');
  String get swipeDownToDislike => _getText('swipe_down_to_dislike');
  String get doubleTapToShuffle => _getText('double_tap_to_shuffle');

  // 食物相关
  String get cuisineType => _getText('cuisine_type');
  String get tasteProfile => _getText('taste_profile');
  String get ingredients => _getText('ingredients');
  String get nutrition => _getText('nutrition');
  String get price => _getText('price');
  String get rating => _getText('rating');

  // 错误和状态消息
  String get loading => _getText('loading');
  String get error => _getText('error');
  String get networkError => _getText('network_error');
  String get tryAgain => _getText('try_again');
  String get success => _getText('success');

  // 设置相关
  String get settings => _getText('settings');
  String get language => _getText('language');
  String get theme => _getText('theme');
  String get notifications => _getText('notifications');
  String get privacy => _getText('privacy');
  String get about => _getText('about');

  // 个人资料
  String get profile => _getText('profile');
  String get favorites => _getText('favorites');
  String get history => _getText('history');
  String get preferences => _getText('preferences');

  // 场景相关
  String get lateNightSnack => _getText('late_night_snack');
  String get fitnessRecovery => _getText('fitness_recovery');
  String get dateNight => _getText('date_night');
  String get familyGathering => _getText('family_gathering');
  String get businessMeal => _getText('business_meal');
  String get quickBite => _getText('quick_bite');

  // AI人格相关
  String get aiPersonalityChef => _getText('ai_personality_chef');
  String get aiPersonalityCute => _getText('ai_personality_cute');
  String get aiPersonalityWise => _getText('ai_personality_wise');
  String get aiPersonalityTrendy => _getText('ai_personality_trendy');
  String get aiPersonalityHomely => _getText('ai_personality_homely');

  // 获取本地化文本
  String _getText(String key) {
    final texts = _getLocalizedTexts();
    return texts[key] ?? key;
  }

  // 根据语言获取文本映射
  Map<String, String> _getLocalizedTexts() {
    switch (locale.languageCode) {
      case 'zh':
        return _chineseTexts;
      case 'en':
        return _englishTexts;
      case 'ja':
        return _japaneseTexts;
      case 'ko':
        return _koreanTexts;
      default:
        return _englishTexts;
    }
  }

  // 中文文本
  static const Map<String, String> _chineseTexts = {
    'app_name': '吃什么',
    'welcome_title': '🍽️ 欢迎来到吃什么',
    'welcome_subtitle': '让AI帮你选择美味佳肴',
    
    'bubble_screen_title': '口味星球',
    'bubble_screen_subtitle': '在零重力环境中探索您的味蕾偏好',
    'selected_bubbles': '已选择',
    'clear_selection': '重新选择',
    'generate_recommendations': '启动美食推荐',
    
    'recommendations_title': '为您推荐',
    'no_recommendations': '暂无推荐，请先选择您的偏好',
    'ai_recommendation': 'AI推荐',
    'match_score': '匹配度',
    
    'tap_to_select': '点击选择',
    'swipe_up_to_like': '上滑喜欢',
    'swipe_down_to_dislike': '下滑不喜欢',
    'double_tap_to_shuffle': '双击添加扰动',
    
    'cuisine_type': '菜系',
    'taste_profile': '口味',
    'ingredients': '食材',
    'nutrition': '营养',
    'price': '价格',
    'rating': '评分',
    
    'loading': '加载中...',
    'error': '出错了',
    'network_error': '网络连接失败',
    'try_again': '重试',
    'success': '成功',
    
    'settings': '设置',
    'language': '语言',
    'theme': '主题',
    'notifications': '通知',
    'privacy': '隐私',
    'about': '关于',
    
    'profile': '个人资料',
    'favorites': '收藏',
    'history': '历史',
    'preferences': '偏好',
    
    'late_night_snack': '深夜食堂',
    'fitness_recovery': '健身餐',
    'date_night': '情侣约会',
    'family_gathering': '家庭聚餐',
    'business_meal': '商务用餐',
    'quick_bite': '快速充饥',
    
    'ai_personality_chef': '美食大厨',
    'ai_personality_cute': '萌宠助手',
    'ai_personality_wise': '养生大师',
    'ai_personality_trendy': '潮流达人',
    'ai_personality_homely': '居家妈妈',
  };

  // 英文文本
  static const Map<String, String> _englishTexts = {
    'app_name': 'EatWhat',
    'welcome_title': '🍽️ Welcome to EatWhat',
    'welcome_subtitle': 'Let AI help you choose delicious cuisine',
    
    'bubble_screen_title': 'Flavor Planet',
    'bubble_screen_subtitle': 'Explore your taste preferences in zero gravity',
    'selected_bubbles': 'Selected',
    'clear_selection': 'Clear Selection',
    'generate_recommendations': 'Generate Recommendations',
    
    'recommendations_title': 'Recommended for You',
    'no_recommendations': 'No recommendations yet, please select your preferences',
    'ai_recommendation': 'AI Recommendation',
    'match_score': 'Match Score',
    
    'tap_to_select': 'Tap to Select',
    'swipe_up_to_like': 'Swipe Up to Like',
    'swipe_down_to_dislike': 'Swipe Down to Dislike',
    'double_tap_to_shuffle': 'Double Tap to Shuffle',
    
    'cuisine_type': 'Cuisine',
    'taste_profile': 'Taste',
    'ingredients': 'Ingredients',
    'nutrition': 'Nutrition',
    'price': 'Price',
    'rating': 'Rating',
    
    'loading': 'Loading...',
    'error': 'Error',
    'network_error': 'Network connection failed',
    'try_again': 'Try Again',
    'success': 'Success',
    
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'notifications': 'Notifications',
    'privacy': 'Privacy',
    'about': 'About',
    
    'profile': 'Profile',
    'favorites': 'Favorites',
    'history': 'History',
    'preferences': 'Preferences',
    
    'late_night_snack': 'Late Night Snack',
    'fitness_recovery': 'Fitness Recovery',
    'date_night': 'Date Night',
    'family_gathering': 'Family Gathering',
    'business_meal': 'Business Meal',
    'quick_bite': 'Quick Bite',
    
    'ai_personality_chef': 'Gourmet Chef',
    'ai_personality_cute': 'Cute Helper',
    'ai_personality_wise': 'Wise Master',
    'ai_personality_trendy': 'Trendy Friend',
    'ai_personality_homely': 'Homely Mom',
  };

  // 日文文本（基础版本）
  static const Map<String, String> _japaneseTexts = {
    'app_name': '何を食べる',
    'welcome_title': '🍽️ 何を食べるへようこそ',
    'welcome_subtitle': 'AIが美味しい料理選びをお手伝い',
    
    'bubble_screen_title': 'フレーバープラネット',
    'bubble_screen_subtitle': '無重力環境で味覚の好みを探索',
    'selected_bubbles': '選択済み',
    'clear_selection': '選択をクリア',
    'generate_recommendations': 'おすすめを生成',
    
    'loading': '読み込み中...',
    'error': 'エラー',
    'try_again': '再試行',
    'success': '成功',
  };

  // 韩文文本（基础版本）
  static const Map<String, String> _koreanTexts = {
    'app_name': '뭘 먹을까',
    'welcome_title': '🍽️ 뭘 먹을까에 오신 것을 환영합니다',
    'welcome_subtitle': 'AI가 맛있는 음식 선택을 도와드립니다',
    
    'bubble_screen_title': '플레이버 플래닛',
    'bubble_screen_subtitle': '무중력 환경에서 미각 선호도 탐색',
    'selected_bubbles': '선택됨',
    'clear_selection': '선택 지우기',
    'generate_recommendations': '추천 생성',
    
    'loading': '로딩 중...',
    'error': '오류',
    'try_again': '다시 시도',
    'success': '성공',
  };
}

/// 本地化委托
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}