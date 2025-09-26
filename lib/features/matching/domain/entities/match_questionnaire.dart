import 'package:equatable/equatable.dart';

enum MatchQuestionType {
  select,
  locationBand,
  timeRange,
  chips,
  slider,
  radio,
  checkbox,
  multiSelect,
}

class MatchQuestionOption extends Equatable {
  const MatchQuestionOption({
    required this.label,
    String? value,
    this.weight = 1,
  }) : value = value ?? label;

  final String label;
  final String value;
  final double weight;

  @override
  List<Object?> get props => <Object?>[label, value, weight];
}

class MatchQuestionItem extends Equatable {
  const MatchQuestionItem({
    required this.id,
    required this.type,
    this.options = const <MatchQuestionOption>[],
    this.min,
    this.max,
    this.step,
    this.isCritical = false,
  });

  final String id;
  final MatchQuestionType type;
  final List<MatchQuestionOption> options;
  final double? min;
  final double? max;
  final double? step;
  final bool isCritical;

  @override
  List<Object?> get props => <Object?>[
    id,
    type,
    options,
    min,
    max,
    step,
    isCritical,
  ];
}

class MatchSurveySection extends Equatable {
  const MatchSurveySection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<MatchQuestionItem> items;

  @override
  List<Object?> get props => <Object?>[id, title, items];
}

class MatchSurveyDefinition extends Equatable {
  const MatchSurveyDefinition({
    required this.sections,
    required this.seriousnessFormula,
    required this.firstMessagePrompts,
  });

  final List<MatchSurveySection> sections;
  final String seriousnessFormula;
  final List<String> firstMessagePrompts;

  @override
  List<Object?> get props => <Object?>[
    sections,
    seriousnessFormula,
    firstMessagePrompts,
  ];
}

const MatchSurveyDefinition defaultMatchSurvey = MatchSurveyDefinition(
  sections: <MatchSurveySection>[
    MatchSurveySection(
      id: 'basics',
      title: '기본 정보',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'age_band',
          type: MatchQuestionType.select,
          isCritical: true,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '20-24'),
            MatchQuestionOption(label: '25-29'),
            MatchQuestionOption(label: '30-34'),
            MatchQuestionOption(label: '35-39'),
            MatchQuestionOption(label: '40+'),
          ],
        ),
        MatchQuestionItem(
          id: 'area',
          type: MatchQuestionType.locationBand,
          options: <MatchQuestionOption>[MatchQuestionOption(label: '구/시 단위')],
        ),
        MatchQuestionItem(
          id: 'height_band',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '<160'),
            MatchQuestionOption(label: '160-164'),
            MatchQuestionOption(label: '165-169'),
            MatchQuestionOption(label: '170-174'),
            MatchQuestionOption(label: '175+'),
          ],
        ),
        MatchQuestionItem(
          id: 'smoking',
          type: MatchQuestionType.radio,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'no'),
            MatchQuestionOption(label: 'occasionally'),
            MatchQuestionOption(label: 'yes', weight: 0.5),
          ],
        ),
        MatchQuestionItem(
          id: 'religion',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'none'),
            MatchQuestionOption(label: 'protestant'),
            MatchQuestionOption(label: 'catholic'),
            MatchQuestionOption(label: 'buddhist'),
            MatchQuestionOption(label: 'other'),
          ],
        ),
      ],
    ),
    MatchSurveySection(
      id: 'lifestyle',
      title: '생활 리듬',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'shift',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'day'),
            MatchQuestionOption(label: '2-shift'),
            MatchQuestionOption(label: '3-shift'),
            MatchQuestionOption(label: 'night'),
          ],
        ),
        MatchQuestionItem(id: 'sleep', type: MatchQuestionType.timeRange),
        MatchQuestionItem(
          id: 'weekend_style',
          type: MatchQuestionType.chips,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '집콕'),
            MatchQuestionOption(label: '카페'),
            MatchQuestionOption(label: '등산'),
            MatchQuestionOption(label: '러닝'),
            MatchQuestionOption(label: '영화'),
            MatchQuestionOption(label: '독서'),
            MatchQuestionOption(label: '여행'),
          ],
        ),
        MatchQuestionItem(
          id: 'consumption_style',
          type: MatchQuestionType.radio,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'saving'),
            MatchQuestionOption(label: 'experience'),
          ],
        ),
      ],
    ),
    MatchSurveySection(
      id: 'marriage',
      title: '결혼/가족 계획',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'marriage_timeline',
          type: MatchQuestionType.select,
          isCritical: true,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '1년 내'),
            MatchQuestionOption(label: '2-3년'),
            MatchQuestionOption(label: '4년+'),
            MatchQuestionOption(label: '미정'),
          ],
        ),
        MatchQuestionItem(
          id: 'children_plan',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '원함'),
            MatchQuestionOption(label: '미정'),
            MatchQuestionOption(label: '원치않음'),
          ],
        ),
        MatchQuestionItem(
          id: 'finance_style',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '공동'),
            MatchQuestionOption(label: '부분공동'),
            MatchQuestionOption(label: '분리'),
          ],
        ),
        MatchQuestionItem(
          id: 'parents_care',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '함께거주 가능'),
            MatchQuestionOption(label: '가까이'),
            MatchQuestionOption(label: '독립선호'),
          ],
        ),
      ],
    ),
    MatchSurveySection(
      id: 'values',
      title: '가치관/갈등해결',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'decision_style',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '대화로 합의'),
            MatchQuestionOption(label: '역할분담'),
            MatchQuestionOption(label: '상황별'),
          ],
        ),
        MatchQuestionItem(
          id: 'conflict_style',
          type: MatchQuestionType.select,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: '즉시대화'),
            MatchQuestionOption(label: '시간두기'),
            MatchQuestionOption(label: '중재선호'),
          ],
        ),
      ],
    ),
    MatchSurveySection(
      id: 'distance',
      title: '거리/이동',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'max_travel_minutes',
          type: MatchQuestionType.slider,
          min: 10,
          max: 120,
          step: 10,
        ),
        MatchQuestionItem(
          id: 'long_distance_ok',
          type: MatchQuestionType.radio,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'yes'),
            MatchQuestionOption(label: 'no'),
            MatchQuestionOption(label: 'maybe'),
          ],
        ),
      ],
    ),
    MatchSurveySection(
      id: 'filters',
      title: '필수 제외',
      items: <MatchQuestionItem>[
        MatchQuestionItem(
          id: 'exclude_smoking',
          type: MatchQuestionType.checkbox,
        ),
        MatchQuestionItem(
          id: 'exclude_religion',
          type: MatchQuestionType.multiSelect,
          options: <MatchQuestionOption>[
            MatchQuestionOption(label: 'none'),
            MatchQuestionOption(label: 'protestant'),
            MatchQuestionOption(label: 'catholic'),
            MatchQuestionOption(label: 'buddhist'),
            MatchQuestionOption(label: 'other'),
          ],
        ),
      ],
    ),
  ],
  seriousnessFormula:
      'w1*marriage_timeline + w2*children_plan + w3*finance_style + w4*first_message_behavior',
  firstMessagePrompts: <String>[
    '주말엔 보통 어떻게 보내세요?',
    '이상적인 데이트는?',
    '여행 스타일이 궁금해요.',
  ],
);
