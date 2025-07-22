# 《吃什么》应用部署指南

## 📋 概述

本指南详细说明了《吃什么》应用从开发到生产环境的完整部署流程，包括多平台发布、国际化配置、CI/CD流水线等。

## 🎯 部署目标

### 平台支持
- **iOS**: App Store (全球发布)
- **Android**: Google Play Store, 华为应用市场, 小米应用商店
- **Web**: PWA支持，部署到CDN
- **Desktop**: macOS App Store, Microsoft Store

### 地区支持
- **主要市场**: 中国大陆、香港、台湾、新加坡
- **扩展市场**: 美国、加拿大、澳大利亚、日本、韩国
- **语言支持**: 中文(简/繁)、英语、日语、韩语

## 🚀 阶段一：开发环境配置

### 1.1 环境变量配置

创建不同环境的配置文件：

#### `.env.development`
```bash
# 开发环境配置
ENVIRONMENT=development
API_BASE_URL=https://dev-api.eatwhat.app
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
SILICONFLOW_API_KEY=your_dev_api_key
ENABLE_AI_RECOMMENDATIONS=true
ENABLE_DEBUG_MODE=true
ENABLE_ANALYTICS=false
AI_CACHE_DURATION=300
```

#### `.env.staging`
```bash
# 测试环境配置
ENVIRONMENT=staging
API_BASE_URL=https://staging-api.eatwhat.app
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
SILICONFLOW_API_KEY=your_staging_api_key
ENABLE_AI_RECOMMENDATIONS=true
ENABLE_DEBUG_MODE=false
ENABLE_ANALYTICS=true
AI_CACHE_DURATION=600
```

#### `.env.production`
```bash
# 生产环境配置
ENVIRONMENT=production
API_BASE_URL=https://api.eatwhat.app
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
SILICONFLOW_API_KEY=your_prod_api_key
ENABLE_AI_RECOMMENDATIONS=true
ENABLE_DEBUG_MODE=false
ENABLE_ANALYTICS=true
AI_CACHE_DURATION=1800
```

### 1.2 Flutter版本和依赖

```yaml
# pubspec.yaml - 生产版本
environment:
  sdk: '>=3.4.4 <4.0.0'
  flutter: '>=3.16.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # 核心依赖 - 锁定版本确保稳定性
  provider: 6.1.2
  dio: 5.4.0
  hive_flutter: 1.1.0
  cached_network_image: 3.3.1
  flutter_screenutil: 5.9.3
  
  # 性能优化
  flame: 1.15.0
  flutter_animate: 4.5.0
  
  # 国际化
  intl: 0.19.0
```

## 🔧 阶段二：构建配置优化

### 2.1 Android构建优化

#### `android/app/build.gradle.kts`
```kotlin
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.eatwhat.app"
        minSdk 21
        targetSdk 34
        versionCode flutter.versionCode
        versionName flutter.versionName
        
        // 多语言资源配置
        resConfigs "zh", "en", "ja", "ko"
        
        // 网络安全配置
        networkSecurityConfig = file("res/xml/network_security_config.xml")
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("release")
        }
        
        create("staging") {
            initWith(getByName("release"))
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            isDebuggable = true
        }
    }
    
    // 支持多架构
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = true
        }
    }
    
    // 包大小优化
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    
    // 崩溃报告
    implementation("com.google.firebase:firebase-crashlytics-ktx:18.6.1")
    implementation("com.google.firebase:firebase-analytics-ktx:21.5.0")
}
```

### 2.2 iOS构建优化

#### `ios/Runner/Info.plist`
```xml
<dict>
    <key>CFBundleDisplayName</key>
    <string>吃什么</string>
    <key>CFBundleIdentifier</key>
    <string>com.eatwhat.app</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <!-- 支持的语言 -->
    <key>CFBundleLocalizations</key>
    <array>
        <string>zh-Hans</string>
        <string>zh-Hant</string>
        <string>en</string>
        <string>ja</string>
        <string>ko</string>
    </array>
    
    <!-- 网络权限 -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>api.eatwhat.app</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
            </dict>
        </dict>
    </dict>
    
    <!-- 相机和照片权限 -->
    <key>NSCameraUsageDescription</key>
    <string>用于拍摄美食照片和AI识别</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>用于选择美食照片进行推荐</string>
</dict>
```

## 🌐 阶段三：国际化配置

### 3.1 应用商店元数据

#### App Store (中文)
```
应用名称: 吃什么 - AI美食推荐
副标题: 智能推荐，探索美味
关键词: 美食,推荐,AI,餐厅,外卖,菜谱
描述:
《吃什么》是一款革命性的AI美食推荐应用，通过独特的气泡交互系统帮您发现专属美食。

🌟 核心功能
• 创新气泡选择：物理引擎驱动的沉浸式选择体验
• AI智能推荐：个性化美食推荐，越用越懂你
• 多场景适配：深夜食堂、健身餐、约会餐厅全覆盖
• 实时外卖对接：一键下单，美食送达

🎯 为什么选择《吃什么》
• 告别选择困难症
• 发现隐藏美食
• 节省决策时间
• 提升生活品质
```

#### App Store (English)
```
App Name: EatWhat - AI Food Recommendations
Subtitle: Smart recommendations, discover delicious food
Keywords: food,recommendation,AI,restaurant,delivery,recipe
Description:
EatWhat is a revolutionary AI-powered food recommendation app that helps you discover your perfect meal through an innovative bubble interaction system.

🌟 Core Features
• Innovative Bubble Selection: Immersive physics-driven selection experience
• AI Smart Recommendations: Personalized food suggestions that learn your taste
• Multi-scenario Support: Late night snacks, fitness meals, date restaurants
• Real-time Delivery Integration: One-tap ordering with instant delivery

🎯 Why Choose EatWhat
• End decision paralysis
• Discover hidden gems
• Save decision time
• Enhance life quality
```

### 3.2 应用截图配置

每个地区需要准备5-10张应用截图，展示：
1. 气泡交互界面
2. AI推荐结果
3. 个性化设置
4. 美食详情页面
5. 订单流程

## 🔄 阶段四：CI/CD流水线

### 4.1 GitHub Actions配置

#### `.github/workflows/deploy.yml`
```yaml
name: Deploy EatWhat App

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.16.0'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run tests
        run: flutter test
        
      - name: Analyze code
        run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
          
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Configure environment
        run: |
          echo "${{ secrets.ENV_PRODUCTION }}" > .env
          
      - name: Build APK
        run: |
          flutter build apk --release --split-per-abi
          
      - name: Build AAB
        run: |
          flutter build appbundle --release
          
      - name: Upload to Play Store
        if: startsWith(github.ref, 'refs/tags/')
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.eatwhat.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Configure environment
        run: |
          echo "${{ secrets.ENV_PRODUCTION }}" > .env
          
      - name: Build iOS
        run: |
          flutter build ios --release --no-codesign
          
      - name: Build and upload to App Store
        if: startsWith(github.ref, 'refs/tags/')
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          # 使用 fastlane 或 xcrun 上传到 App Store Connect
          echo "Building and uploading to App Store Connect..."

  build-web:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Build Web
        run: |
          flutter build web --release
          
      - name: Deploy to CDN
        run: |
          # 部署到 CDN (Cloudflare, AWS CloudFront 等)
          echo "Deploying to CDN..."
```

## 📊 阶段五：监控和分析

### 5.1 应用性能监控

#### Firebase Analytics配置
```dart
// lib/core/analytics/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  // 用户行为追踪
  static Future<void> trackBubbleSelection(String bubbleType) async {
    await _analytics.logEvent(
      name: 'bubble_selection',
      parameters: {'bubble_type': bubbleType},
    );
  }
  
  static Future<void> trackFoodRecommendation(String foodId, double score) async {
    await _analytics.logEvent(
      name: 'food_recommendation',
      parameters: {
        'food_id': foodId,
        'recommendation_score': score,
      },
    );
  }
  
  static Future<void> trackUserRetention(int daysSinceInstall) async {
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: {'days_since_install': daysSinceInstall},
    );
  }
}
```

### 5.2 商业化数据追踪

```dart
// 收益追踪
static Future<void> trackRevenue({
  required double amount,
  required String currency,
  required String source,
}) async {
  await _analytics.logEvent(
    name: 'revenue_generated',
    parameters: {
      'value': amount,
      'currency': currency,
      'source': source,
    },
  );
}

// 转化率追踪
static Future<void> trackConversion({
  required String funnelStep,
  required bool converted,
}) async {
  await _analytics.logEvent(
    name: 'conversion_tracking',
    parameters: {
      'funnel_step': funnelStep,
      'converted': converted,
    },
  );
}
```

## 🚀 阶段六：上线检查清单

### 6.1 技术检查
- [ ] 所有单元测试通过
- [ ] 集成测试覆盖率 > 80%
- [ ] 性能测试满足要求 (启动时间 < 3s, 60fps)
- [ ] 内存使用 < 200MB
- [ ] 包大小 < 50MB (Android), < 100MB (iOS)
- [ ] 支持离线基本功能
- [ ] 国际化文本完整
- [ ] 深色模式适配
- [ ] 无障碍功能支持

### 6.2 业务检查
- [ ] AI推荐准确率 > 85%
- [ ] 外卖平台API对接完成
- [ ] 支付流程测试通过
- [ ] 客服系统配置
- [ ] 法律条款和隐私政策
- [ ] 应用商店元数据准备
- [ ] 营销材料设计完成

### 6.3 运营检查
- [ ] 用户反馈收集机制
- [ ] A/B测试框架部署
- [ ] 推送通知系统
- [ ] 社交媒体账号建立
- [ ] 客户支持流程
- [ ] 数据备份和恢复
- [ ] 安全漏洞扫描

## 📈 阶段七：上线后优化

### 7.1 数据监控指标

#### 核心KPI
- **用户获取**: DAU, MAU, 新用户注册率
- **用户激活**: 首次推荐完成率, 功能使用深度
- **用户留存**: 次日留存, 7日留存, 30日留存
- **用户推荐**: K因子, 病毒传播系数
- **商业化**: ARPU, LTV, 付费转化率

#### 技术指标
- **性能**: 应用启动时间, 崩溃率, ANR率
- **质量**: 应用商店评分, 用户反馈
- **基础设施**: API响应时间, 服务可用性

### 7.2 持续优化计划

#### 月度优化
- 根据用户反馈优化UI/UX
- A/B测试新功能
- 推荐算法调优
- 性能监控和优化

#### 季度更新
- 新功能发布
- 新市场扩展
- 合作伙伴接入
- 商业模式优化

## 🌍 国际化扩展计划

### Phase 1: 亚洲市场 (3-6个月)
- 🇨🇳 中国大陆 (主市场)
- 🇭🇰 香港
- 🇹🇼 台湾
- 🇸🇬 新加坡

### Phase 2: 英语市场 (6-12个月)
- 🇺🇸 美国
- 🇨🇦 加拿大
- 🇦🇺 澳大利亚
- 🇬🇧 英国

### Phase 3: 其他亚洲市场 (12-18个月)
- 🇯🇵 日本
- 🇰🇷 韩国
- 🇹🇭 泰国
- 🇻🇳 越南

## 📞 技术支持

### 联系方式
- 技术支持: tech@eatwhat.app
- 商务合作: business@eatwhat.app
- 用户反馈: feedback@eatwhat.app

### 文档资源
- API文档: https://docs.eatwhat.app
- 开发者社区: https://developers.eatwhat.app
- 状态页面: https://status.eatwhat.app

---

**注意**: 本部署指南应根据实际项目需求和技术栈进行调整。建议在正式部署前进行充分的测试和安全审查。