import 'package:eatwhat_app/v2/core/models/cold_start_questionnaire.dart';
import 'package:eatwhat_app/v2/core/services/cold_start_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cold-start questionnaire covers the V2 MVP constraint fields', () {
    final questionsById = {
      for (final question in QuestionnaireQuestions.questions)
        question.id: question,
    };

    expect(questionsById[1]?.title, contains('菜系'));
    expect(questionsById[2]?.title, contains('忌口'));
    expect(questionsById[3]?.title, contains('口味'));
    expect(questionsById[4]?.title, contains('场景'));
    expect(questionsById[5]?.title, contains('人数'));
    expect(questionsById[6]?.options, contains('20 分钟内'));
    expect(questionsById[7]?.title, contains('预算'));
    expect(questionsById[8]?.title, contains('心情'));
  });

  test('cold-start answers initialize time, budget and mood preference signals',
      () async {
    final data = ColdStartQuestionnaireData(
      completedAt: DateTime(2026, 6, 14),
      answers: const [
        ColdStartAnswer(
          questionId: 1,
          selectedOptions: ['川菜'],
        ),
        ColdStartAnswer(
          questionId: 2,
          selectedOptions: ['无忌口'],
        ),
        ColdStartAnswer(
          questionId: 3,
          selectedOptions: ['鲜'],
        ),
        ColdStartAnswer(
          questionId: 4,
          selectedOptions: [],
          singleOption: '在家做饭',
        ),
        ColdStartAnswer(
          questionId: 5,
          selectedOptions: [],
          singleOption: '2-3人',
        ),
        ColdStartAnswer(
          questionId: 6,
          selectedOptions: [],
          singleOption: '20 分钟内',
        ),
        ColdStartAnswer(
          questionId: 7,
          selectedOptions: [],
          singleOption: '30 元内',
        ),
        ColdStartAnswer(
          questionId: 8,
          selectedOptions: [],
          singleOption: '想吃热乎',
        ),
      ],
    );

    final preference = await ColdStartService().initializeUserPreference(data);

    expect(preference.tastePreferences['时间_快手'], greaterThan(0));
    expect(preference.tastePreferences['预算_经济'], greaterThan(0));
    expect(preference.tastePreferences['心情_暖胃'], greaterThan(0));
    expect(preference.tastePreferences['人数_小份'], greaterThan(0));
  });
}
