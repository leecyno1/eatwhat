import 'package:eatwhat_app/v2/features/style_lab/young_food_style_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const YoungFoodStyleLabApp());
}

class YoungFoodStyleLabApp extends StatelessWidget {
  const YoungFoodStyleLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '吃什么 · 年轻品牌 UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        splashFactory: InkSparkle.splashFactory,
      ),
      home: const YoungFoodStyleLabPage(),
    );
  }
}
