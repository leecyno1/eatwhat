import 'package:flutter/material.dart';
import 'features/recipe/screens/modern_recipe_recommendation_screen.dart';
import 'screens/recipe_demo_screen.dart';

/// 菜谱功能测试应用
class RecipeTestApp extends StatelessWidget {
  const RecipeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '《吃什么》- 菜谱测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'PingFang SC',
      ),
      home: const RecipeDemoScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/recipes': (context) => const ModernRecipeRecommendationScreen(),
      },
    );
  }
}

void main() {
  runApp(const RecipeTestApp());
}
