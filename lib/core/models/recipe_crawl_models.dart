// 菜谱抓取进度追踪
enum RecipeCrawlPhase {
  idle,
  fetchingCategories,
  fetchingRecipes,
  processingRecipes,
  completed,
  error,
}

// 菜谱抓取进度数据
class RecipeCrawlProgress {
  final RecipeCrawlPhase phase;
  final double progressPercentage;
  final int totalRecipes;
  final int processedRecipes;
  final int successfulRecipes;
  final int failedRecipes;
  final String? currentMessage;

  RecipeCrawlProgress({
    required this.phase,
    double? progressPercentage,
    required this.totalRecipes,
    required this.processedRecipes,
    this.successfulRecipes = 0,
    this.failedRecipes = 0,
    this.currentMessage,
  }) : progressPercentage = progressPercentage ??
            (totalRecipes > 0 ? processedRecipes / totalRecipes : 0.0);

  @override
  String toString() {
    return 'RecipeCrawlProgress(phase: $phase, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%, processed: $processedRecipes/$totalRecipes)';
  }
}

// 菜谱抓取结果
class RecipeCrawlResult {
  final bool success;
  final int totalRecipes;
  final int successfulRecipes;
  final int failedRecipes;
  final List<dynamic> recipes; // 添加recipes字段
  final List<String> errors;
  final String? errorMessage;
  final Duration duration;

  RecipeCrawlResult({
    bool? success,
    int? totalRecipes,
    int? successfulRecipes,
    int? failedRecipes,
    int? totalProcessed,
    int? successCount,
    int? failureCount,
    this.recipes = const [],
    this.errors = const [],
    this.errorMessage,
    required this.duration,
  })  : totalRecipes = totalRecipes ?? totalProcessed ?? recipes.length,
        successfulRecipes = successfulRecipes ?? successCount ?? 0,
        failedRecipes = failedRecipes ?? failureCount ?? 0,
        success = success ??
            ((failedRecipes ?? failureCount ?? 0) == 0 &&
                (errorMessage == null || errorMessage.isEmpty));

  int get totalProcessed => totalRecipes;
  int get successCount => successfulRecipes;
  int get failureCount => failedRecipes;

  double get successRate =>
      totalRecipes > 0 ? (successfulRecipes / totalRecipes) : 0.0;

  @override
  String toString() {
    return 'RecipeCrawlResult(success: $success, total: $totalRecipes, successful: $successfulRecipes, failed: $failedRecipes)';
  }
}
