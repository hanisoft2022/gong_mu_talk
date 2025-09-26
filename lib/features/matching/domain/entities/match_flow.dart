import 'package:equatable/equatable.dart';

enum MatchFlowStage {
  interestExpression,
  conversation,
  meetingPreparation,
  relationshipProgress,
}

extension MatchFlowStageLabel on MatchFlowStage {
  String get label {
    switch (this) {
      case MatchFlowStage.interestExpression:
        return '관심 표명';
      case MatchFlowStage.conversation:
        return '첫 대화';
      case MatchFlowStage.meetingPreparation:
        return '만남 준비';
      case MatchFlowStage.relationshipProgress:
        return '관계 진행';
    }
  }

  MatchFlowStage? get next {
    final int index = MatchFlowStage.values.indexOf(this);
    if (index + 1 >= MatchFlowStage.values.length) {
      return null;
    }
    return MatchFlowStage.values[index + 1];
  }
}

class MatchFlowPolicy extends Equatable {
  const MatchFlowPolicy({
    required this.firstConversationSla,
    required this.reminderDelay,
    required this.maxDailyCurations,
    required this.premiumBonusCurations,
  });

  final Duration firstConversationSla;
  final Duration reminderDelay;
  final int maxDailyCurations;
  final int premiumBonusCurations;

  static const MatchFlowPolicy defaultPolicy = MatchFlowPolicy(
    firstConversationSla: Duration(hours: 24),
    reminderDelay: Duration(hours: 24),
    maxDailyCurations: 5,
    premiumBonusCurations: 2,
  );

  @override
  List<Object?> get props => <Object?>[
    firstConversationSla,
    reminderDelay,
    maxDailyCurations,
    premiumBonusCurations,
  ];
}

class MatchFlowChecklist extends Equatable {
  const MatchFlowChecklist({required this.stage, required this.guides});

  final MatchFlowStage stage;
  final List<String> guides;

  static const List<MatchFlowChecklist> defaultGuides = <MatchFlowChecklist>[
    MatchFlowChecklist(
      stage: MatchFlowStage.meetingPreparation,
      guides: <String>['만남 일정과 위치를 지정 지인과 공유하기', '긴급 상황시 신고 경로 미리 확인하기'],
    ),
    MatchFlowChecklist(
      stage: MatchFlowStage.relationshipProgress,
      guides: <String>[
        '생활비 분담에 대한 대화 나누기',
        '휴가 사용 계획과 가족 행사 참석 범위 조율하기',
        '종교 및 가족 전통에 대한 기대치 공유하기',
      ],
    ),
  ];

  @override
  List<Object?> get props => <Object?>[stage, guides];
}
