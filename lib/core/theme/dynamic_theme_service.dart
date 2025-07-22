import 'package:flutter/material.dart';
import 'dart:async';

/// 动态主题服务 - 根据时间调整背景颜色
class DynamicThemeService extends ChangeNotifier {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  
  /// 当前背景渐变
  LinearGradient get backgroundGradient => _getTimeBasedGradient();
  
  /// 当前时间
  DateTime get currentTime => _currentTime;
  
  /// 当前时间段描述
  String get timePeriodDescription => _getTimePeriodDescription();

  DynamicThemeService() {
    _startTimer();
  }

  /// 启动定时器，每分钟更新一次
  /// 暂时禁用以解决气泡乱窜问题
  void _startTimer() {
    // 禁用频繁的定时器，避免不必要的界面重建
    // _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
    //   _currentTime = DateTime.now();
    //   notifyListeners();
    // });
    
    // 只设置一次初始时间，不再定时更新
    _currentTime = DateTime.now();
  }

  /// 根据时间获取渐变背景
  LinearGradient _getTimeBasedGradient() {
    final hour = _currentTime.hour;
    
    // 早晨 6-10点：白色渐变黄色
    if (hour >= 6 && hour < 10) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFF8), // 极淡的白色
          Color(0xFFFFFAE6), // 极淡的黄色
          Color(0xFFFFF8DC), // 玉米丝色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 上午 10-12点：黄色渐变更深的黄色
    else if (hour >= 10 && hour < 12) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFAE6), // 极淡的黄色
          Color(0xFFFFF2CC), // 淡黄色
          Color(0xFFFFE6B3), // 稍深的黄色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 中午 12-14点：黄色渐变绿色
    else if (hour >= 12 && hour < 14) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF2CC), // 淡黄色
          Color(0xFFF0FFF0), // 蜜瓜绿
          Color(0xFFE6FFE6), // 极淡的绿色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 下午 14-17点：绿色渐变更深的绿色
    else if (hour >= 14 && hour < 17) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE6FFE6), // 极淡的绿色
          Color(0xFFCCFFCC), // 淡绿色
          Color(0xFFB3FFB3), // 稍深的绿色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 傍晚 17-19点：绿色渐变红色
    else if (hour >= 17 && hour < 19) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFCCFFCC), // 淡绿色
          Color(0xFFFFE6E6), // 极淡的粉红
          Color(0xFFFFCCCC), // 淡红色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 晚上 19-22点：红色渐变更深的红色
    else if (hour >= 19 && hour < 22) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFCCCC), // 淡红色
          Color(0xFFFFB3B3), // 稍深的红色
          Color(0xFFFF9999), // 桃红色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // 深夜 22-6点：红色渐变黑色
    else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF9999), // 桃红色
          Color(0xFF666666), // 灰色
          Color(0xFF333333), // 深灰色
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }

  /// 获取时间段描述
  String _getTimePeriodDescription() {
    final hour = _currentTime.hour;
    
    if (hour >= 6 && hour < 10) {
      return '清晨';
    } else if (hour >= 10 && hour < 12) {
      return '上午';
    } else if (hour >= 12 && hour < 14) {
      return '中午';
    } else if (hour >= 14 && hour < 17) {
      return '下午';
    } else if (hour >= 17 && hour < 19) {
      return '傍晚';
    } else if (hour >= 19 && hour < 22) {
      return '晚上';
    } else {
      return '深夜';
    }
  }

  /// 获取与背景相匹配的文字颜色
  Color get primaryTextColor {
    final hour = _currentTime.hour;
    
    // 深夜时使用白色文字，其他时间使用深色文字
    if (hour >= 22 || hour < 6) {
      return Colors.white.withValues(alpha: 0.9);
    } else {
      return Colors.black87;
    }
  }

  /// 获取次要文字颜色
  Color get secondaryTextColor {
    final hour = _currentTime.hour;
    
    if (hour >= 22 || hour < 6) {
      return Colors.white.withValues(alpha: 0.7);
    } else {
      return Colors.black54;
    }
  }

  /// 获取强调色
  Color get accentColor {
    final hour = _currentTime.hour;
    
    if (hour >= 6 && hour < 10) {
      return const Color(0xFFFFD700); // 金色
    } else if (hour >= 10 && hour < 14) {
      return const Color(0xFF32CD32); // 石灰绿
    } else if (hour >= 14 && hour < 17) {
      return const Color(0xFF228B22); // 森林绿
    } else if (hour >= 17 && hour < 19) {
      return const Color(0xFFFF6347); // 番茄红
    } else if (hour >= 19 && hour < 22) {
      return const Color(0xFFDC143C); // 深红色
    } else {
      return const Color(0xFF9370DB); // 中紫色
    }
  }

  /// 手动设置时间（用于测试）
  void setTime(DateTime time) {
    _currentTime = time;
    notifyListeners();
  }

  /// 获取动画渐变（用于平滑过渡）
  LinearGradient getAnimatedGradient(double animationValue) {
    final current = _getTimeBasedGradient();
    
    // 添加动画效果，让渐变有轻微的呼吸感
    final animatedColors = current.colors.map((color) {
      final opacity = 0.8 + (animationValue * 0.2); // 0.8 - 1.0
      return color.withValues(alpha: opacity);
    }).toList();
    
    return LinearGradient(
      begin: current.begin,
      end: current.end,
      colors: animatedColors,
      stops: current.stops,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 时间段枚举
enum TimePeriod {
  dawn,      // 清晨 6-10
  morning,   // 上午 10-12
  noon,      // 中午 12-14
  afternoon, // 下午 14-17
  evening,   // 傍晚 17-19
  night,     // 晚上 19-22
  midnight,  // 深夜 22-6
}

/// 获取当前时间段
TimePeriod getCurrentTimePeriod() {
  final hour = DateTime.now().hour;
  
  if (hour >= 6 && hour < 10) {
    return TimePeriod.dawn;
  } else if (hour >= 10 && hour < 12) {
    return TimePeriod.morning;
  } else if (hour >= 12 && hour < 14) {
    return TimePeriod.noon;
  } else if (hour >= 14 && hour < 17) {
    return TimePeriod.afternoon;
  } else if (hour >= 17 && hour < 19) {
    return TimePeriod.evening;
  } else if (hour >= 19 && hour < 22) {
    return TimePeriod.night;
  } else {
    return TimePeriod.midnight;
  }
}