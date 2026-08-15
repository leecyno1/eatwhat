# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

《吃什么》(EatWhat) is a Flutter mobile app that helps users make food decisions through V2 taste-card selection, local-first recipe recall, and AI-powered recommendation refinement. The current product path is `main.dart -> AppV2 -> HomePage -> DecisionPage -> ResultPage`.

**Key Features:**
- Bubble-based food preference selection with custom physics engine
- 46-dimensional taste vector recommendation system
- Local unified recipe database with 43 dishes / 53 variants
- HowToCook recipe database with 195 recipes
- AI-powered food suggestions via SiliconFlow/MiniMax
- Delivery platform integration (Meituan, Eleme, Dianping)

**Current mainline:** add new product work under `lib/v2` unless you are intentionally fixing legacy code. `lib/core` still contains reused services such as database access and environment config. The older `lib/features` screens are retained for compatibility and reference, but they are not the active app entry path.

## Quick Start

### Environment Setup

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure environment variables:**
```bash
# Copy the example file
cp .env.example .env

# Edit .env for local development only:
# - SILICONFLOW_API_KEY (optional; enables live AI recommendations)
# - MINIMAX_API_KEY (optional; enables live image generation)
# - Platform/proxy keys (optional; enables delivery/dine-in execution)
```

`.env` is ignored by git and is not packaged as a Flutter asset. For CI or release builds, prefer `--dart-define` or a backend proxy:

```bash
flutter run --dart-define=SILICONFLOW_API_KEY=<key>
```

Do not ship long-lived AI, delivery, or proxy secrets in the client app. Production integrations should use a backend proxy or short-lived tokens.

3. **Run the app:**
```bash
# Debug mode
flutter run

# On specific device
flutter run -d <device-id>

# Release mode
flutter run --release
```

### Development Commands

```bash
# Code quality
flutter analyze                    # Static analysis
flutter clean                      # Clean build cache

# Testing
./test_ios_device.sh --list       # List available iOS devices
./test_ios_device.sh --quick <id> # Quick device test
./test_ios_device.sh --full <id>  # Full test with cache cleanup
./test_howtocook_integration.sh   # Test recipe database integration

# Database inspection
sqlite3 assets/data/howtocook_complete_recipes.db "SELECT COUNT(*) FROM howtocook_recipes;"
```

**Common Device IDs:**
- iPhone 12 Pro Max: `00008140-001C29D93E60801C`

## Architecture

### Application Structure

```
lib/
├── main.dart                      # App entry point, loads EnvConfig
├── v2/
│   ├── app_v2.dart               # Main app widget (MaterialApp + ScreenUtil)
│   ├── core/
│   │   ├── data/                 # V2 models, repositories, schema adapters
│   │   ├── services/             # V2 recommendation, cache, execution, speech
│   │   ├── external/platform/    # Meituan/Eleme/Dianping provider abstraction
│   │   └── theme/                # FluidTheme (light/dark themes)
│   └── features/
│       ├── home/                 # Taste-card selection and freeform input
│       ├── decision/             # Local recall + AI refinement transition
│       ├── result/               # Recommendation result surface
│       ├── details/              # Recipe detail and HowToCook library
│       ├── execution/            # Cook/order/dine-in execution flows
│       └── favorites/            # Favorite tags and recipes
├── core/                         # Foundation layer
│   ├── config/
│   │   └── env_config.dart       # Environment variable management
│   ├── models/                   # Data models
│   │   ├── recipe.dart           # 25+ fields with taste profiles
│   │   ├── food.dart             # UI-optimized display model
│   │   ├── bubble.dart           # Interactive bubble with physics
│   │   └── user_preference.dart  # ML-ready preference tracking
│   ├── services/                 # 35+ business services
│   │   ├── unified_food_data_service.dart           # Central data orchestrator
│   │   ├── recipe_database_service.dart             # Recipe CRUD operations
│   │   ├── howtocook_database_service.dart          # HowToCook integration
│   │   ├── vectorized_recommendation_engine.dart    # ML-based ranking
│   │   ├── taste_mapping_algorithm_service.dart     # 46D taste vectors
│   │   ├── user_preference_manager.dart             # Preference learning
│   │   ├── xiachufang_crawler_service.dart          # Recipe crawling
│   │   ├── delivery_api_service.dart                # Platform integration
│   │   ├── secure_storage_service.dart              # Encrypted storage
│   │   └── auth_service.dart                        # User authentication
│   ├── utils/                    # Utilities
│   │   ├── performance_optimizer.dart  # Frame monitoring, auto-optimization
│   │   ├── memory_manager.dart         # GC optimization
│   │   └── secure_logger.dart          # Sanitized logging
│   ├── physics/                  # Custom physics engine for bubbles
│   └── ai/                       # AI integration services
└── features/                     # Legacy feature modules
    ├── auth/                     # Login, registration
    ├── bubble/                   # Bubble interaction system
    ├── recommendation/           # Food recommendation UI
    ├── search/                   # Search and filtering
    ├── favorites/                # User favorites
    ├── history/                  # Browse history
    ├── delivery/                 # Delivery platform integration
    ├── howtocook/                # Recipe browsing
    ├── recipe/                   # Recipe details
    ├── preferences/              # User preference management
    ├── settings/                 # App settings
    └── user/                     # User profile
```

### Active V2 Flow

```
HomePage
  -> TasteInferenceInput
  -> DecisionPage
  -> V2Phase2RecommendationService
  -> UnifiedRecommendationServiceV2
  -> GenerationService.refineRecommendations()
  -> V2HowToCookRecipeService.enrichRecipe()
  -> ResultPage
```

### Core Architecture Patterns

**State Management:**
- Provider pattern with ChangeNotifier controllers
- Controllers must implement `dispose()` to prevent memory leaks
- Use `DebouncedNotifier` for high-frequency updates

**Data Flow:**
```
User Input → Controller → Service Layer → Repository → Data Source
                ↓                                          ↓
            UI Update ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
```

**Service Layer Pattern:**
- Singleton services with lazy initialization
- Dependency injection via constructor parameters
- Each service handles its own error recovery

### Key Service Architecture

#### V2Phase2RecommendationService
Current V2 recommendation orchestrator:

```dart
V2Phase2RecommendationService
├── UnifiedRecommendationServiceV2 // Local SQLite recall and heuristic scoring
├── GenerationService              // AI refinement, reasons, intro, nutrition
├── AiService                      // AI fallback direct recommendation
└── V2HowToCookRecipeService       // HowToCook detail enrichment
```

**Recommendation Flow:**
1. **Taste Selection** → Build `TasteInferenceInput` from card gestures and freeform text
2. **Local Recall** → Query `unified_recipes.db` through FTS / LIKE fallback
3. **Heuristic Ranking** → Score matches using tags, ingredients, favorites, feedback, and recent recipe penalties
4. **AI Refinement** → Reorder candidates and generate reasons/summary when configured
5. **HowToCook Enrichment** → Add ingredients, steps, and local image assets
6. **Result Display** → Render recommendation details, favorites, pairings, nutrition, and execution options

#### Recipe Database Integration

**HowToCook Database:**
- Location: `assets/data/howtocook_complete_recipes.db`
- 195 recipes in the current checked-in database
- Categories: 主食, 菜品, 汤, 甜品, etc.
- Fields: name, category, ingredients, steps, cooking_time, difficulty, taste_profile

**Unified Recipe Database:**
- Location: `assets/data/unified_recipes.db`
- Current size: 43 dishes, 53 recipe variants, 16 tags
- Primary V2 recall source via `UnifiedRecipeDatabaseService`

**Taste Mapping Algorithm:**
- 46-dimensional taste feature vectors
- Similarity algorithms: cosine, Euclidean, Manhattan
- Real-time preference learning from user interactions

**Sync Services:**
- `XiachufangCrawlerService`: Simulated data crawling with quality control
- `RecipeRecommendationSyncService`: Full/incremental sync with progress monitoring
- `TasteMappingAlgorithmService`: Taste feature extraction and vectorization

### Model Architecture

**Rich Domain Models:**
- **Recipe**: 25+ fields including taste profiles, seasonal info, equipment requirements, nutritional data
- **Food**: Display model converted from Recipe with UI-optimized fields (imageUrl, rating, tags)
- **Bubble**: Interactive element with physics properties (velocity, mass, friction) and preference mapping
- **UserPreference**: Comprehensive tracking with ML features (taste vectors, interaction history)

**Serialization:**
- All models implement `toJson()`/`fromJson()`
- Null safety with default values
- Hive type adapters for local storage

### Environment Configuration

**EnvConfig** (`lib/core/config/env_config.dart`):
- Loads optional local `.env` values for development
- Reads `--dart-define` values before `.env`
- Provides typed access to environment variables
- Validates required configuration
- Graceful fallback to defaults if local config is missing

**Critical Configuration:**
```dart
EnvConfig.siliconFlowApiKey      // AI service API key
EnvConfig.aiModelName            // AI model selection
EnvConfig.enableAiRecommendations // Feature toggle
EnvConfig.debugMode              // Debug logging
```

Configuration priority:
1. `--dart-define`
2. local `.env` when present
3. built-in fallback defaults

## Development Guidelines

### Code Style

**Naming Conventions:**
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: `_leadingUnderscore`

**Best Practices:**
- Use `debugPrint` instead of `print`
- Use `const` constructors for performance
- Implement `dispose()` in all controllers
- Avoid complex computations in `build()` methods
- Use `copyWith()` for immutable model updates

### State Management Pattern

```dart
// Controller
class FoodController extends ChangeNotifier {
  List<Food> _foods = [];
  
  List<Food> get foods => _foods;
  
  Future<void> loadFoods() async {
    _foods = await _foodService.getFoods();
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

// Provider setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FoodController()),
  ],
  child: MyApp(),
)

// Widget usage
Consumer<FoodController>(
  builder: (context, controller, child) {
    return ListView.builder(
      itemCount: controller.foods.length,
      itemBuilder: (context, index) => FoodCard(controller.foods[index]),
    );
  },
)
```

### Data Model Pattern

```dart
class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  
  Recipe({required this.id, required this.name, required this.ingredients});
  
  // Immutable updates
  Recipe copyWith({String? name, List<String>? ingredients}) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
    );
  }
  
  // Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ingredients': ingredients,
  };
  
  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    ingredients: List<String>.from(json['ingredients'] as List),
  );
}
```

### Performance Optimization

**PerformanceOptimizer** monitors:
- Frame rendering time (target: 60fps)
- Interaction latency
- Memory usage
- Automatic optimization suggestions

**Best Practices:**
- Use `const` constructors wherever possible
- Implement `ObjectPool` for frequently created objects
- Use `DebouncedNotifier` for high-frequency state updates
- Optimize list rendering with `ListView.builder`
- Cache expensive computations

### Security

**SecureLogger:**
- Automatically sanitizes sensitive data (API keys, tokens, passwords)
- Safe for production logging

**SecureStorageService:**
- Encrypted local storage using `flutter_secure_storage`
- Use for tokens, user credentials, sensitive preferences

**API Security:**
- `ApiSignatureService`: Request signing and verification
- `PasswordHashUtil`: Secure password hashing with salt

### Error Handling

**Global Error Handler:**
- Catches unhandled exceptions
- Displays graceful fallback UI
- Provides app restart capability

**Service-Level Recovery:**
```dart
try {
  final result = await _apiService.fetchData();
  return result;
} catch (e) {
  debugPrint('Error fetching data: $e');
  // Return cached data or default value
  return _getCachedData() ?? _getDefaultData();
}
```

## Testing

### Test Scripts

```bash
# iOS device testing
./test_ios_device.sh --quick <device-id>   # Quick test (no cache cleanup)
./test_ios_device.sh --full <device-id>    # Full test (with cleanup)
./test_ios_device.sh --list                # List available devices

# HowToCook integration test
./test_howtocook_integration.sh            # Verify database and build
```

### Test Strategy

- **Unit Tests**: Core services and algorithms (recommendation engine, taste mapping)
- **Widget Tests**: UI components (bubble interactions, food cards)
- **Integration Tests**: User workflows (search → select → recommend)
- **Device Tests**: Real hardware validation (iOS/Android)

## Key Technical Decisions

### Why Provider over BLoC/Riverpod?
Provider offers simplicity and direct Flutter integration, suitable for the app's moderate complexity. The team is familiar with Provider patterns, reducing learning curve.

### Why Custom Physics Engine?
The bubble interaction system requires fine-grained control over physics simulation (collision detection, velocity damping, boundary constraints) that standard animation libraries don't provide. Using Flame engine allows 60fps performance with complex interactions.

### Why 46-Dimensional Taste Vectors?
Based on food science research covering taste dimensions (sweet, salty, sour, bitter, umami), texture (crispy, soft, chewy), temperature preferences, spice levels, and cooking methods. This granularity improves recommendation accuracy significantly over simple tag-based systems.

### Why SQLite over Hive for Recipes?
SQLite provides:
- Complex querying capabilities (JOIN, aggregation, full-text search)
- Better performance for structured recipe datasets
- Standard SQL interface for data migration
- Hive is still used for user preferences and app state (simpler key-value storage)

### Chinese/English Mixed Codebase
- **Chinese**: UI text, comments explaining business logic, user-facing strings
- **English**: Code (classes, variables, methods), technical documentation, API interfaces
- Rationale: Serves Chinese users while maintaining international developer accessibility

## Common Issues

### iOS Build Failures
```bash
# Clean and rebuild
flutter clean
cd ios && pod deinstall && pod install
cd .. && flutter pub get
flutter run
```

### Database Not Found
Ensure `assets/data/howtocook_complete_recipes.db` is listed in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/data/howtocook_complete_recipes.db
```

### Environment Variables Not Loading
1. For local development, verify `.env` exists in the project root.
2. For CI/release, verify the expected `--dart-define` values are passed.
3. Ensure `EnvConfig.init()` is called in `main()` before `runApp()`.
4. Do not add `.env` to `pubspec.yaml` assets; secrets must not be packaged into the app.

### Dependency Version Conflicts
The project uses compatible versions to avoid conflicts:
- `ml_linalg: ^13.12.6` (not latest, but stable with current dependencies)
- Check `pubspec.yaml` for version constraints before upgrading

## Git Workflow

**Commit Message Format:**
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `perf:` Performance improvement
- `docs:` Documentation
- `test:` Testing
- `chore:` Build/tooling changes

**Example:**
```bash
git commit -m "feat: 添加基于余弦相似度的推荐算法优化"
git commit -m "fix: 修复气泡碰撞检测边界问题"
```

## Additional Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Provider Package**: https://pub.dev/packages/provider
- **Flame Engine**: https://flame-engine.org
- **HowToCook Project**: https://github.com/Anduin2017/HowToCook
