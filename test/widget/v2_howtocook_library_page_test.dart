import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'assets/images/howtocook_gallery/library.jpg') {
        return ByteData(1);
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('HowToCookLibraryPage 展示菜谱库列表并支持搜索', (tester) async {
    final service = V2HowToCookRecipeService(
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '下饭热菜',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
          'cooking_time': 35,
          'servings': 2,
        },
        {
          'id': 'htc_2',
          'name': '蒜蓉西兰花',
          'description': '清爽快手蔬菜',
          'difficulty': 2,
          'category': '素菜',
          'subcategory': '家常',
          'cooking_time': 10,
          'servings': 2,
        },
        {
          'id': 'htc_3',
          'name': '冬瓜排骨汤',
          'description': '清润热汤',
          'difficulty': 2,
          'category': '汤羹',
          'subcategory': '炖煮',
          'cooking_time': 40,
          'servings': 3,
        },
      ],
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_2',
          'name': '蒜蓉西兰花',
          'description': '清爽快手蔬菜',
          'difficulty': 2,
          'category': '素菜',
          'cooking_time': 10,
          'servings': 2,
        },
      ],
      assetIndexLoader: () async => '''
        {
          "items": [
            {
              "recipeId": "htc_1",
              "name": "黄焖鸡",
              "assetImageUrls": ["assets/images/howtocook_gallery/library.jpg"],
              "sourceProject": "HowToCook"
            }
          ]
        }
      ''',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HowToCookLibraryPage(service: service),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('家常菜谱'), findsOneWidget);
    expect(find.text('黄焖鸡'), findsOneWidget);
    expect(find.text('蒜蓉西兰花'), findsOneWidget);
    expect(find.text('冬瓜排骨汤'), findsOneWidget);
    expect(find.text('实拍图'), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/images/howtocook_gallery/library.jpg'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '西兰花');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('蒜蓉西兰花'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('汤羹').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('冬瓜排骨汤'), findsOneWidget);
    expect(find.text('黄焖鸡'), findsNothing);
  });
}
