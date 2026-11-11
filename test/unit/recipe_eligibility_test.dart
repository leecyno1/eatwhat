import 'package:eatwhat_app/v2/core/services/recipe_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeEligibility', () {
    group('冰箱常用别名的排除一致性', () {
      for (final (label, alias) in [
        ('番茄', '西红柿'),
        ('西红柿', '番茄'),
        ('土豆', '马铃薯'),
        ('马铃薯', '土豆'),
        ('香菜', '芫荽'),
        ('芫荽', '香菜'),
      ]) {
        for (final mode in ['dislike', 'dietary', 'freeform']) {
          test('$mode 的 $label 也排除 $alias', () {
            final gate = RecipeEligibility(
              dislikedLabels: mode == 'dislike' ? [label] : [],
              dietaryRestrictions: mode == 'dietary' ? [label] : [],
              freeformRequirement: mode == 'freeform' ? '不要$label' : '',
            );
            expect(
                gate.evaluate(name: '家常菜', ingredients: [alias, '鸡蛋']).allowed,
                isFalse);
            expect(
                gate.evaluate(name: '家常菜', ingredients: ['青菜', '鸡蛋']).allowed,
                isTrue);
          });
        }
      }
    });

    group('餐食候选边界', () {
      for (final category in [
        '调料',
        '调味品',
        '酱汁',
        '基础食材加工',
        '半成品加工',
        '饮品',
        '饮料',
        '咖啡',
        '酒类',
        '甜品',
        '甜点',
        'condiment',
        'semi-finished',
        'drink',
        'dessert',
      ]) {
        test('默认不把明确 $category 类别作为一餐', () {
          final result = RecipeEligibility().evaluate(
            name: '新配方',
            tags: [category, '主食', '快手', '夜宵'],
          );
          expect(result.allowed, isFalse);
          expect(result.rejectionReason, contains('餐食'));
        });
      }

      for (final name in [
        '炸串酱料',
        '番茄红酱',
        '糖醋汁',
        '简易版炒糖色',
        '牛油火锅底料',
        'B52轰炸机',
        'Mojito莫吉托',
        '金汤力',
        '奶茶',
        '柠檬水',
        '提拉米苏',
      ]) {
        test('缺分类时也排除已核对的非餐精确菜名 $name', () {
          expect(RecipeEligibility().evaluate(name: name).allowed, isFalse);
        });
      }

      for (final name in ['宫保鸡丁', '酱牛肉', '啤酒鸭', '糖醋里脊', '蒜蓉虾', '吐司果酱']) {
        test('不以酱酒糖或污染的调味蘸料标签误杀 $name', () {
          expect(
            RecipeEligibility().evaluate(
              name: name,
              ingredients: ['酱油', '料酒', '糖'],
              tags: ['荤菜', '调味蘸料', '酱香', '啤酒'],
            ).allowed,
            isTrue,
          );
        });
      }

      for (final name in [
        '凉皮',
        '半成品意面',
        '空气炸锅羊排',
        '空气炸锅鸡翅中',
        '速冻水饺',
        '速冻汤圆',
        '速冻馄饨'
      ]) {
        test('半成品分类中已核对的成餐做法保留 $name', () {
          expect(
            RecipeEligibility().evaluate(name: name, tags: ['半成品加工']).allowed,
            isTrue,
          );
        });
      }

      test('甜或清爽不是显式甜品饮品请求', () {
        for (final request in ['', '甜', '清爽', '夜宵', '不要甜品', '不想喝饮品']) {
          final policy = RecipeEligibility(freeformRequirement: request);
          expect(policy.evaluate(name: '新甜点', tags: ['甜品']).allowed, isFalse);
          expect(policy.evaluate(name: '新饮料', tags: ['饮品']).allowed, isFalse);
        }
      });

      test('下午茶场景同时请求甜品和非酒精饮品', () {
        final teatime = RecipeEligibility(
          explicitRequestLabels: const ['下午茶'],
        );
        expect(
          teatime.evaluate(name: '提拉米苏', tags: ['甜品']).allowed,
          isTrue,
        );
        expect(teatime.evaluate(name: '奶茶', tags: ['饮品']).allowed, isTrue);
        expect(
          teatime.evaluate(
              name: 'B52轰炸机', tags: ['饮品'], ingredients: ['伏特加']).allowed,
          isFalse,
        );
      });

      test('显式甜品和非酒精饮品请求独立开放，不互相放行', () {
        final dessert = RecipeEligibility(freeformRequirement: '想吃甜品');
        final drink = RecipeEligibility(freeformRequirement: '想喝饮品');
        expect(dessert.evaluate(name: '提拉米苏', tags: ['甜品']).allowed, isTrue);
        expect(dessert.evaluate(name: '奶茶', tags: ['饮品']).allowed, isFalse);
        expect(drink.evaluate(name: '奶茶', tags: ['饮品']).allowed, isTrue);
        expect(drink.evaluate(name: '提拉米苏', tags: ['甜品']).allowed, isFalse);
        expect(drink.evaluate(name: 'B52轰炸机', tags: ['饮品']).allowed, isFalse);
        expect(
            drink.evaluate(
              name: '新特调',
              tags: ['饮品'],
              ingredients: ['伏特加', '柠檬'],
            ).allowed,
            isFalse);
        expect(drink.evaluate(name: '糖醋汁', tags: ['调料']).allowed, isFalse);
      });
    });

    test('dislike 素食是排除该标签而不是反过来要求素食', () {
      final eligibility = RecipeEligibility(dislikedLabels: ['素食']);
      expect(eligibility.evaluate(name: '烤鸡', ingredients: ['鸡肉']).allowed,
          isTrue);
      expect(eligibility.evaluate(name: '炒青菜', tags: ['素食']).allowed, isFalse);
    });

    for (final restriction in ['素食', '蛋奶素食']) {
      test('$restriction 允许蛋奶但拒绝午餐肉', () {
        final eligibility =
            RecipeEligibility(dietaryRestrictions: [restriction]);
        expect(
            eligibility
                .evaluate(name: '牛奶蒸蛋', ingredients: ['鸡蛋', '牛奶']).allowed,
            isTrue);
        expect(
            eligibility.evaluate(name: '上汤娃娃菜', ingredients: ['午餐肉']).allowed,
            isFalse);
      });
    }

    test('英语按词边界匹配，不将 eggplant 当鸡蛋或 butterfly 当黄油', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['鸡蛋', '奶']);
      expect(
          eligibility.evaluate(
              name: 'eggplant butterfly pasta',
              ingredients: ['eggplant']).allowed,
          isTrue);
      expect(eligibility.evaluate(name: 'rice', ingredients: ['EGG']).allowed,
          isFalse);
      expect(
          eligibility.evaluate(name: 'rice', ingredients: ['butter']).allowed,
          isFalse);
    });

    for (final text in ['喜欢花生、鸡蛋和牛奶', '我喜欢素食，也喜欢鸡肉', '不要太油，喜欢花生']) {
      test('不把正向文本 $text 当禁忌', () {
        final eligibility = RecipeEligibility(freeformRequirement: text);
        expect(
            eligibility.evaluate(
                name: '家常饭', ingredients: ['花生', '鸡蛋', '牛奶', '鸡肉']).allowed,
            isTrue);
      });
    }

    for (final text in [
      '不要素食',
      '我不想吃素',
      '不想要纯素',
      '不要 蛋奶素',
      '不要清真',
    ]) {
      test('否定饮食方式 $text 不强制该方式', () {
        final eligibility = RecipeEligibility(freeformRequirement: text);
        expect(eligibility.hasDietaryRestrictions, isFalse);
        expect(
          eligibility.evaluate(name: '家常饭', ingredients: ['猪肉', '鸡蛋']).allowed,
          isTrue,
        );
      });
    }

    for (final text in ['我吃素', '蛋奶素', '今天想吃素', '不要辣，我吃素']) {
      test('肯定饮食方式 $text 正常生效且保留蛋奶', () {
        final eligibility = RecipeEligibility(freeformRequirement: text);
        expect(eligibility.evaluate(name: '肉饭', ingredients: ['猪肉']).allowed,
            isFalse);
        expect(
          eligibility.evaluate(name: '蒸蛋', ingredients: ['鸡蛋', '牛奶']).allowed,
          isTrue,
        );
      });
    }

    test('自由文本明确不吃鸡肉时排除鸡肉但保留鸡蛋', () {
      final eligibility = RecipeEligibility(freeformRequirement: '不要鸡肉，喜欢鸡蛋');
      expect(eligibility.evaluate(name: '家常饭', ingredients: ['鸡肉']).allowed,
          isFalse);
      expect(eligibility.evaluate(name: '蒸蛋', ingredients: ['鸡蛋']).allowed,
          isTrue);
    });

    test('鸡蛋忌口不误杀高蛋白标签或植物蛋白', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['鸡蛋']);
      expect(
          eligibility.evaluate(
              name: '豆腐饭', ingredients: ['豌豆蛋白'], tags: ['高蛋白']).allowed,
          isTrue);
      expect(eligibility.evaluate(name: '蛋白羹', ingredients: ['蛋白 2个']).allowed,
          isFalse);
    });

    for (final entry in {
      '虾过敏': '虾仁',
      '不要鱼': '鲈鱼',
      '螃蟹过敏': '蟹肉',
      '不吃贝类': '蛤蜊',
      '不要香菜': '香菜',
    }.entries) {
      test('成员忌口 ${entry.key} 命中实际食材', () {
        final eligibility = RecipeEligibility(freeformRequirement: entry.key);
        expect(
          eligibility.evaluate(name: '家常饭', ingredients: [entry.value]).allowed,
          isFalse,
        );
        expect(
          eligibility.evaluate(name: '菌菇饭', ingredients: [
            '鱼腥草',
            '海鲜菇',
            '蟹味菇',
            '鸡腿菇',
            'eggplant',
          ]).allowed,
          isTrue,
        );
      });
    }

    for (final text in [
      '喜欢虾和鱼，也喜欢香菜',
      '不要鱼腥草',
      '不要海鲜菇',
      '不要蟹味菇',
      '不要eggplant',
    ]) {
      test('成员忌口不误解析正向或植物词 $text', () {
        final eligibility = RecipeEligibility(freeformRequirement: text);
        expect(eligibility.hasDietaryRestrictions, isFalse);
        expect(
          eligibility.evaluate(name: '家常饭', ingredients: ['虾仁', '鸡蛋']).allowed,
          isTrue,
        );
      });
    }

    test('海鲜忌口不误杀植物复合词', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['海鲜']);
      expect(
        eligibility.evaluate(name: '鱼香茄子', ingredients: [
          '茄子',
          '鱼腥草',
          '海鲜菇',
          '蟹味菇',
        ]).allowed,
        isTrue,
      );
    });

    test('未知结构化食材按字面排除而不推断同义食材', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['荞麦']);
      expect(eligibility.evaluate(name: '荞麦面', ingredients: ['荞麦粉']).allowed,
          isFalse);
      expect(eligibility.evaluate(name: '小麦面', ingredients: ['小麦粉']).allowed,
          isTrue);
    });

    test('未知标签不猜含义，structured 和 dislike 均按字面排除', () {
      final unknown = RecipeEligibility(dietaryRestrictions: ['星际轻盈']);
      expect(
          unknown.evaluate(
              name: '花生饭', ingredients: ['花生'], tags: ['星际轻盈']).allowed,
          isFalse);
      final disliked = RecipeEligibility(dislikedLabels: ['星际轻盈']);
      expect(disliked.evaluate(name: '花生饭', tags: ['星际轻盈']).allowed, isFalse);
    });

    test('明确忌口的 AI 即便自称安全也不能用空成分通过核验', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['花生']);
      final result = eligibility.evaluate(
          name: '安全饭',
          description: '放心吃',
          ingredients: [' '],
          requireIngredients: true);
      expect(result.allowed, isFalse);
      expect(result.rejectionReason, contains('食材缺失'));
    });

    test('词表外结构化忌口不推断食材，但也不能核验空成分 AI', () {
      final eligibility = RecipeEligibility(dietaryRestrictions: ['荞麦']);
      expect(
          eligibility.evaluate(name: '家常饭', requireIngredients: true).allowed,
          isFalse);
      expect(
          RecipeEligibility(dietaryRestrictions: ['无忌口'])
              .evaluate(name: '家常饭', requireIngredients: true)
              .allowed,
          isTrue);
    });

    test('无禁忌不因 AI 缺成分而强制清空候选', () {
      expect(
          RecipeEligibility()
              .evaluate(name: '家常饭', requireIngredients: true)
              .allowed,
          isTrue);
    });

    test('未知耗时可保留但只标未核验，明确超时仍排除', () {
      final eligibility = RecipeEligibility(maxTimeMinutes: 15);
      for (final time in [null, 0, -1]) {
        expect(
            eligibility.evaluate(name: '家常饭', totalTimeMinutes: time).allowed,
            isTrue);
        expect(eligibility.timeNotes(time).single, contains('耗时未核验'));
      }
      expect(eligibility.evaluate(name: '家常饭', totalTimeMinutes: 20).allowed,
          isFalse);
      expect(eligibility.timeNotes(10).single, contains('15 分钟内可完成'));
    });
  });
}
