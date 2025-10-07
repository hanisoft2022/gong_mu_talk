/// Firestore에 봉급표 및 수당 기준 데이터를 업로드하는 스크립트
///
/// 사용법:
/// ```bash
/// dart run scripts/upload_salary_data.dart
/// ```
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // ignore: avoid_print
  print('🚀 봉급표 데이터 업로드 시작...\n');

  // Firebase 초기화
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  try {
    // 1. 2025년 일반직 봉급표 업로드
    await uploadSalaryTable2025(firestore);

    // 2. 2024년 일반직 봉급표 업로드
    await uploadSalaryTable2024(firestore);

    // 3. 2025년 수당 기준표 업로드
    await uploadAllowanceStandard2025(firestore);

    // ignore: avoid_print
    print('\n✅ 모든 데이터 업로드 완료!');
  } catch (e, stackTrace) {
    // ignore: avoid_print
    print('❌ 업로드 실패: $e');
    // ignore: avoid_print
    print(stackTrace);
  }
}

/// 2025년 일반직 봉급표 업로드
Future<void> uploadSalaryTable2025(FirebaseFirestore firestore) async {
  // ignore: avoid_print
  print('📊 2025년 일반직 봉급표 업로드 중...');

  final data = {
    'year': 2025,
    'track': 'general',
    'grades': {
      '9': {
        'gradeName': '9급',
        'minStep': 1,
        'maxStep': 19,
        'steps': {
          '1': 1956000,
          '2': 2034000,
          '3': 2112000,
          '4': 2190000,
          '5': 2268000,
          '6': 2346000,
          '7': 2424000,
          '8': 2502000,
          '9': 2580000,
          '10': 2658000,
          '11': 2736000,
          '12': 2814000,
          '13': 2892000,
          '14': 2970000,
          '15': 3048000,
          '16': 3126000,
          '17': 3204000,
          '18': 3282000,
          '19': 3360000,
        },
      },
      '8': {
        'gradeName': '8급',
        'minStep': 1,
        'maxStep': 20,
        'steps': {
          '1': 2112000,
          '2': 2196000,
          '3': 2280000,
          '4': 2364000,
          '5': 2448000,
          '6': 2532000,
          '7': 2616000,
          '8': 2700000,
          '9': 2784000,
          '10': 2868000,
          '11': 2952000,
          '12': 3036000,
          '13': 3120000,
          '14': 3204000,
          '15': 3288000,
          '16': 3372000,
          '17': 3456000,
          '18': 3540000,
          '19': 3624000,
          '20': 3708000,
        },
      },
      '7': {
        'gradeName': '7급',
        'minStep': 1,
        'maxStep': 21,
        'steps': {
          '1': 2280000,
          '2': 2376000,
          '3': 2472000,
          '4': 2568000,
          '5': 2664000,
          '6': 2760000,
          '7': 2856000,
          '8': 2952000,
          '9': 3048000,
          '10': 3144000,
          '11': 3240000,
          '12': 3336000,
          '13': 3432000,
          '14': 3528000,
          '15': 3624000,
          '16': 3720000,
          '17': 3816000,
          '18': 3912000,
          '19': 4008000,
          '20': 4104000,
          '21': 4200000,
        },
      },
      '6': {
        'gradeName': '6급',
        'minStep': 1,
        'maxStep': 22,
        'steps': {
          '1': 2472000,
          '2': 2580000,
          '3': 2688000,
          '4': 2796000,
          '5': 2904000,
          '6': 3012000,
          '7': 3120000,
          '8': 3228000,
          '9': 3336000,
          '10': 3444000,
          '11': 3552000,
          '12': 3660000,
          '13': 3768000,
          '14': 3876000,
          '15': 3984000,
          '16': 4092000,
          '17': 4200000,
          '18': 4308000,
          '19': 4416000,
          '20': 4524000,
          '21': 4632000,
          '22': 4740000,
        },
      },
      '5': {
        'gradeName': '5급',
        'minStep': 1,
        'maxStep': 23,
        'steps': {
          '1': 2688000,
          '2': 2814000,
          '3': 2940000,
          '4': 3066000,
          '5': 3192000,
          '6': 3318000,
          '7': 3444000,
          '8': 3570000,
          '9': 3696000,
          '10': 3822000,
          '11': 3948000,
          '12': 4074000,
          '13': 4200000,
          '14': 4326000,
          '15': 4452000,
          '16': 4578000,
          '17': 4704000,
          '18': 4830000,
          '19': 4956000,
          '20': 5082000,
          '21': 5208000,
          '22': 5334000,
          '23': 5460000,
        },
      },
    },
    'metadata': {
      'source': '인사혁신처',
      'updatedAt': '2025-01-01',
      'description': '2025년 일반직공무원 봉급표',
    },
  };

  await firestore.collection('salary_tables').doc('2025_general').set(data);

  // ignore: avoid_print
  print('  ✓ 2025년 일반직 봉급표 업로드 완료');
}

/// 2024년 일반직 봉급표 업로드
Future<void> uploadSalaryTable2024(FirebaseFirestore firestore) async {
  // ignore: avoid_print
  print('📊 2024년 일반직 봉급표 업로드 중...');

  final data = {
    'year': 2024,
    'track': 'general',
    'grades': {
      '9': {
        'gradeName': '9급',
        'minStep': 1,
        'maxStep': 19,
        'steps': {
          '1': 1918000,
          '2': 1994000,
          '3': 2070000,
          '4': 2146000,
          '5': 2222000,
          '6': 2298000,
          '7': 2374000,
          '8': 2450000,
          '9': 2526000,
          '10': 2602000,
          '11': 2678000,
          '12': 2754000,
          '13': 2830000,
          '14': 2906000,
          '15': 2982000,
          '16': 3058000,
          '17': 3134000,
          '18': 3210000,
          '19': 3286000,
        },
      },
      '8': {
        'gradeName': '8급',
        'minStep': 1,
        'maxStep': 20,
        'steps': {
          '1': 2070000,
          '2': 2152000,
          '3': 2234000,
          '4': 2316000,
          '5': 2398000,
          '6': 2480000,
          '7': 2562000,
          '8': 2644000,
          '9': 2726000,
          '10': 2808000,
          '11': 2890000,
          '12': 2972000,
          '13': 3054000,
          '14': 3136000,
          '15': 3218000,
          '16': 3300000,
          '17': 3382000,
          '18': 3464000,
          '19': 3546000,
          '20': 3628000,
        },
      },
    },
    'metadata': {
      'source': '인사혁신처',
      'updatedAt': '2024-01-01',
      'description': '2024년 일반직공무원 봉급표',
    },
  };

  await firestore.collection('salary_tables').doc('2024_general').set(data);

  // ignore: avoid_print
  print('  ✓ 2024년 일반직 봉급표 업로드 완료');
}

/// 2025년 수당 기준표 업로드
Future<void> uploadAllowanceStandard2025(FirebaseFirestore firestore) async {
  // ignore: avoid_print
  print('💰 2025년 수당 기준표 업로드 중...');

  final data = {
    'year': 2025,
    'standards': {
      'mealAllowance': 140000,
      'transportationAllowance': 200000,
      'holidayBonus': 0,
      'longevityAllowance': 0,
      'familyAllowanceSpouse': 40000,
      'familyAllowanceChild': 30000,
      'familyAllowanceParent': 30000,
    },
    'metadata': {
      'source': '인사혁신처',
      'updatedAt': '2025-01-01',
      'description': '2025년 일반직공무원 수당 기준',
      'notes': [
        '명절휴가비: 기본급의 60% × 연 2회',
        '정근수당: 기본급 × 5% × 연 2회 (5년 미만)',
        '정근수당: 기본급 × 연차에 따라 증가 (5년 이상)',
      ],
    },
  };

  await firestore.collection('allowance_standards').doc('2025').set(data);

  // ignore: avoid_print
  print('  ✓ 2025년 수당 기준표 업로드 완료');
}
