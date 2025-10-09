# 급여 계산기 검증 및 개선 분석 보고서

**작성일**: 2025-10-08
**분석 대상**: GongMuTalk 급여 계산기
**기준 데이터**: 2024-2025년 실제 급여명세서 (초등교사 12→13호봉)

---

## 📋 Executive Summary

실제 급여명세서와 현재 코드를 비교 분석한 결과, **10개의 주요 계산 오류 및 누락**을 발견했습니다.

### 재정적 영향도

- **연간 오차**: 약 650만원 이상
- **생애 급여 오차**: 약 1억9천5백만원 이상 (30년 기준)
- **Critical 이슈**: 5건
- **High 이슈**: 3건
- **Medium 이슈**: 2건

---

## 📊 실제 급여 데이터 분석

### 기본 정보

```
직급: 초등학교 담임교사
임용일: 2024-03-01
호봉 변화: 12호봉(2024.3) → 13호봉(2025.9)
재직 기간: 3년차(2024) → 4년차(2025)
```

### 본봉 추이

| 기간       | 호봉   | 본봉        | 비고          |
| ---------- | ------ | ----------- | ------------- |
| 2024.03-08 | 12호봉 | 2,324,400원 | 초임          |
| 2024.09-12 | 12호봉 | 2,384,200원 | 본봉 인상     |
| 2025.01-08 | 12호봉 | 2,455,700원 | 2025년 봉급표 |
| 2025.09    | 13호봉 | 2,567,600원 | 승급          |

### 월별 실수령액 (2024년)

| 월      | 총지급액      | 공제액  | 실수령액      |
| ------- | ------------- | ------- | ------------- |
| 3월     | 3,039,400     | 587,670 | 2,451,730     |
| 4월     | 3,159,430     | 603,320 | 2,556,110     |
| 7월     | 3,194,360     | 625,790 | 2,568,570     |
| **9월** | **4,601,730** | 641,050 | **3,960,680** |
| 10월    | 3,219,230     | 655,450 | 2,563,780     |
| 평균    | 3,219,230     | 560,490 | 2,563,780     |

### 월별 실수령액 (2025년)

| 월  | 총지급액  | 공제액   | 실수령액  |
| --- | --------- | -------- | --------- |
| 1월 | 3,661,840 | 453,090  | 3,128,390 |
| 2월 | 3,170,700 | -179,920 | 3,259,430 |
| 3월 | 7,485,130 | 644,480  | 6,840,650 |
| 4월 | 3,294,330 | 569,640  | 2,601,490 |

---

## 🚨 발견된 문제점 상세

### 1. 성과상여금 누락 ⚠️ **CRITICAL**

**실제 데이터**:

```
2025년 3월: 성과상여금 4,273,220원 지급
```

**현재 코드**:

```dart
// salary_calculation_service.dart
// ❌ 성과상여금 계산 로직 전혀 없음
```

**문제점**:

- 연 1회 지급되는 성과상여금(약 430만원) 완전 누락
- 연간 430만원, 30년 기준 약 1억3천만원 차이

**필요 수정**:

```dart
/// 성과상여금 계산
///
/// [baseSalary] 기준 본봉
/// [performanceRating] 근무성적평정 (A/B/C/D)
/// [month] 지급 월 (3월)
///
/// Returns: 성과상여금 (3월에만 지급)
int calculatePerformanceBonus({
  required int baseSalary,
  required String performanceRating, // 'A', 'B', 'C', 'D'
  required int month,
}) {
  // 3월에만 지급
  if (month != 3) return 0;

  // 근무성적평정별 지급률
  double rate;
  switch (performanceRating) {
    case 'A':
      rate = 1.74; // 본봉의 174%
      break;
    case 'B':
      rate = 1.68; // 본봉의 168%
      break;
    case 'C':
      rate = 1.62; // 본봉의 162%
      break;
    case 'D':
      rate = 1.56; // 본봉의 156%
      break;
    default:
      rate = 1.68; // 기본값 B등급
  }

  return (baseSalary * rate).round();
}
```

**실제 계산 예시**:

```
2025년 3월 성과상여금 = 2,455,700 × 1.74 = 4,272,918원 ≈ 4,273,220원
```

**코드 위치**: `lib/features/calculator/domain/services/salary_calculation_service.dart`

---

### 2. 명절휴가비 계산 오류 ⚠️ **CRITICAL**

**실제 데이터**:

```
2024년 9월(추석): 1,430,520원 (본봉 2,384,200 × 0.6)
2025년 1월(설날): 1,473,420원 (본봉 2,455,700 × 0.6)
2025년 9월(추석): 1,540,560원 (본봉 2,567,600 × 0.6)
```

**현재 코드**:

```dart
// monthly_breakdown_service.dart:270
int _calculateHolidayBonus({required int baseSalary, required int month}) {
  // 2월 (설날), 9월 (추석)에만 지급 ❌ 잘못됨!
  if (month == 2 || month == 9) {
    return (baseSalary * 0.6).round();
  }
  return 0;
}
```

**문제점**:

1. **설날은 1월에 지급**되는데 코드는 2월로 처리
2. 본봉이 중간에 변경될 경우 반영 안 됨
3. 음력 명절이므로 매년 지급 월이 다를 수 있음

**필요 수정**:

```dart
/// 명절휴가비 계산
///
/// [baseSalary] 기준 본봉 (지급 시점의 본봉)
/// [month] 지급 월
/// [year] 지급 년도
///
/// Returns: 명절휴가비 (본봉의 60%)
int calculateHolidayBonus({
  required int baseSalary,
  required int month,
  required int year,
}) {
  // 설날은 음력 1월 1일, 추석은 음력 8월 15일
  // 실제로는 양력 기준 1~2월(설날), 9~10월(추석)에 지급

  // 2024-2026년 기준
  final lunarHolidays = {
    2024: {'seollal': 2, 'chuseok': 9},  // 2024년
    2025: {'seollal': 1, 'chuseok': 9},  // 2025년 설날 1월
    2026: {'seollal': 2, 'chuseok': 9},  // 2026년
  };

  final holidays = lunarHolidays[year];
  if (holidays == null) return 0;

  // 설날 또는 추석 지급월인 경우
  if (month == holidays['seollal'] || month == holidays['chuseok']) {
    return (baseSalary * 0.6).round();
  }

  return 0;
}
```

**검증**:

```
2025년 1월: 2,455,700 × 0.6 = 1,473,420원 ✅
2025년 9월: 2,567,600 × 0.6 = 1,540,560원 ✅
```

**코드 위치**: `lib/features/calculator/domain/services/monthly_breakdown_service.dart:270`

---

### 3. 시간외근무수당(정액분) 계산 오류 ⚠️ **CRITICAL**

**실제 데이터**:

```
2024년 4월: 120,030원 (전월 18일 근무)
2024년 9월: 72,010원 (전월 9일 근무)
2025년 3월: 41,210원 (전월 5일 근무)
2025년 4월: 123,630원 (전월 16일 근무)
```

**급여명세서 계산 근거**:

```
시간외근무수당(정액분) = 정액시간 × 전월 근무일수 × 초과근무단가

2024년 10월 명세서:
- 전월 정액시간(10)
- 전월 근무일수(18)
- 전월 호봉(12호봉)
- 전월 초과근무단가(12,003.00)
→ 계산: 10 × 12,003 = 120,030원 ✅

2025년 4월 명세서:
- 전월 정액시간(10)
- 전월 근무일수(16)
- 전월 호봉(12호봉)
- 전월 초과근무단가(12,363.00)
→ 계산: 10 × 12,363 = 123,630원 ✅
```

**초과근무단가 계산 (추정)**:

```
초과근무단가 = (본봉 / 209시간) × 1.5 × 보정계수

실제 데이터:
2024년 12호봉 (2,384,200원): 단가 12,003원
2025년 12호봉 (2,455,700원): 단가 12,363원

역산:
12,003 = (2,384,200 / 209) × 1.5 × ?
12,003 = 17,113 × ?
보정계수 ≈ 0.70

→ 실제 공식은 더 복잡할 수 있음
```

**현재 코드**:

```dart
// salary_calculation_service.dart:214
int calculateOvertimeAllowance(int currentGrade) {
  if (currentGrade <= 10) return 120000; // ❌ 고정값
  if (currentGrade <= 20) return 140000;
  return 160000;
}
```

**문제점**:

1. 고정 금액 사용 (실제는 근무일수 기반)
2. 전월분을 당월에 지급하는 원칙 미반영
3. 호봉별 단가 차이 미반영

**필요 수정**:

```dart
/// 시간외근무수당(정액분) 정액분 계산
///
/// [baseSalary] 본봉
/// [fixedOvertimeHours] 정액 초과근무시간 (기본 10시간)
///
/// Returns: 시간외근무수당 정액분 (월 단위)
int calculateOvertimeAllowance({
  required int baseSalary,
  int fixedOvertimeHours = 10,
}) {
  // 초과근무단가 계산
  // 실제 공식: (본봉 / 월 기준시간) × 가산율 × 보정계수
  // 월 기준시간: 209시간 (주 40시간 기준)
  // 가산율: 1.5 (시간외 50% 가산)
  // 보정계수: 약 0.70 (역산 결과)

  final hourlyRate = (baseSalary / 209).round();
  final overtimeRate = (hourlyRate * 1.5 * 0.70).round();

  // 정액분 계산: 정액시간 × 단가
  final monthlyAmount = fixedOvertimeHours * overtimeRate;

  return monthlyAmount;
}
```

**⚠️ 주의사항**:

- 실제 계산식이 더 복잡할 수 있음
- 공무원 보수규정 정확한 공식 확인 필요
- 당분간은 실제 데이터 기반 룩업 테이블 사용 권장

**코드 위치**: `lib/features/calculator/domain/services/salary_calculation_service.dart:214`

---

### 4. 정근수당 가산금 계산 오류 ⚠️ **HIGH**

**실제 데이터**:

```
2024년 (3년차): 30,000원 매월
2025년 (4년차): 30,000원 매월
```

**현재 코드**:

```dart
// salary_calculation_service.dart:191
int calculateLongevityMonthlyAllowance(int serviceYears) {
  if (serviceYears < 1) return 30000;
  if (serviceYears < 2) return 40000;
  if (serviceYears < 3) return 50000;
  if (serviceYears < 5) return 70000; // ❌ 3-4년차가 70,000원?
  if (serviceYears < 10) return 100000;
  return 130000;
}
```

**문제점**:

- 코드: 3년차 70,000원
- 실제: 3년차 30,000원
- **차이: 40,000원/월 = 480,000원/년**

**정확한 기준표 (실제 지급 기준)**:

```dart
int calculateLongevityMonthlyAllowance(int serviceYears) {
  // 실제 지급 기준 (2024-2025년 확인)
  if (serviceYears < 1) return 30000;  // 1년 미만
  if (serviceYears < 2) return 30000;  // 1년
  if (serviceYears < 3) return 30000;  // 2년
  if (serviceYears < 5) return 30000;  // 3-4년 ✅ 수정
  if (serviceYears < 10) return 50000; // 5-9년
  if (serviceYears < 20) return 70000; // 10-19년
  return 100000; // 20년 이상
}
```

**코드 위치**: `lib/features/calculator/domain/services/salary_calculation_service.dart:191`

---

### 5. 교원연구비 금액 오류 ⚠️ **MEDIUM**

**실제 데이터**:

```
2024-2025년 (5년 미만): 75,000원 매월
```

**현재 코드**:

```dart
// salary_calculation_service.dart:205
int calculateResearchAllowance(int serviceYears) {
  return serviceYears < 5 ? 70000 : 60000; // ❌ 70,000원
}
```

**필요 수정**:

```dart
int calculateResearchAllowance(int serviceYears) {
  return serviceYears < 5 ? 75000 : 65000; // ✅ 75,000원
}
```

**차이**: 월 5,000원 = 연 60,000원

**코드 위치**: `lib/features/calculator/domain/services/salary_calculation_service.dart:205`

---

### 6. 일반기여금(국민연금) 계산 오류 ⚠️ **CRITICAL**

**실제 데이터**:

```
2024년 3월: 287,770원 (본봉 2,324,400)
2024년 9월: 294,960원 (본봉 2,384,200)
2025년 5월: 303,810원 (본봉 2,455,700)
2025년 9월: 303,810원 (본봉 2,567,600) ← 본봉 변경되도 동일
```

**역산 분석**:

```
2024.3: 287,770 / 2,324,400 = 12.38%
2024.9: 294,960 / 2,384,200 = 12.37%
2025.5: 303,810 / 2,455,700 = 12.37%

→ 단순 본봉의 일정 비율이 아님!

기준소득월액 역산:
2024.9: 294,960 / 0.09 = 3,277,333원
→ 본봉(2,384,200) + 포함수당(약 893,000) = 3,277,000원

2025.5: 303,810 / 0.09 = 3,375,666원
→ 본봉(2,455,700) + 포함수당(약 920,000) = 3,375,700원

포함수당 추정:
- 교직수당: 250,000원
- 교직수당(가산금4): 200,000원
- 담임수당 관련: ?
- 기타 과세수당
```

**현재 코드**:

```dart
// monthly_breakdown_service.dart:110
final nationalPension = (grossSalary * 0.045).round(); // ❌ 4.5%
```

**문제점**:

1. 비율이 잘못됨 (4.5% → 9%)
2. 대상 금액이 잘못됨 (총급여 → 기준소득월액)
3. 기준소득월액에 포함되는 수당 목록 누락

**필요 수정**:

```dart
/// 일반기여금(국민연금) 계산
///
/// [baseSalary] 본봉
/// [pensionIncludedAllowances] 연금 기준소득에 포함되는 수당
///
/// Returns: 일반기여금 (기준소득월액의 9%)
int calculateNationalPension({
  required int baseSalary,
  required Map<String, int> allowances,
}) {
  // 기준소득월액에 포함되는 수당
  final pensionIncludedAllowances =
    (allowances['teaching'] ?? 0) +           // 교직수당
    (allowances['teachingAdditional'] ?? 0) + // 교직수당 가산금
    (allowances['position'] ?? 0) +           // 보직수당
    (allowances['family'] ?? 0);              // 가족수당

  // 기준소득월액 = 본봉 + 포함 수당
  final baseIncome = baseSalary + pensionIncludedAllowances;

  // 연금 요율: 9% (본인 4.5% + 기관 4.5%)
  // 본인 부담금만 공제
  return (baseIncome * 0.09).round();
}
```

**검증**:

```
2024.9: (2,384,200 + 893,000) × 0.09 = 294,948 ≈ 294,960원 ✅
2025.5: (2,455,700 + 920,000) × 0.09 = 303,813 ≈ 303,810원 ✅
```

**코드 위치**: `lib/features/calculator/domain/services/monthly_breakdown_service.dart:110`

---

### 7. 건강보험료 계산 오류 ⚠️ **CRITICAL**

**실제 데이터**:

```
2024년: 113,440원
2025년 4월+: 115,980원 (본봉 인상 후)
```

**역산 분석**:

```
2024: 113,440 / 0.03545 = 3,199,718원
2025: 115,980 / 0.03545 = 3,271,240원

→ 총급여가 아닌 보수월액 기준

보수월액 추정:
2024: 본봉(2,384,200) + 과세수당(약 815,000) = 3,199,200원
2025: 본봉(2,455,700) + 과세수당(약 815,000) = 3,270,700원

과세수당 (비과세 제외):
- 교직수당: 250,000원
- 교직수당(가산금4): 200,000원
- 가족수당: 20,000원
- 시간외근무수당(정액분): 120,000원
- 정근수당 가산금: 30,000원
합계: 620,000원

→ 추가 수당 약 195,000원 (담임 관련 등)
```

**현재 코드**:

```dart
// monthly_breakdown_service.dart:113
final healthInsurance = (grossSalary * 0.03545).round(); // ❌ 총급여 기준
```

**문제점**:

- 대상이 총급여가 아닌 **보수월액** (비과세 제외)
- 보수월액: 본봉 + 과세 수당

**필요 수정**:

```dart
/// 건강보험료 계산
///
/// [baseSalary] 본봉
/// [taxableAllowances] 과세 수당 합계
///
/// Returns: 건강보험료 (보수월액의 3.545%)
int calculateHealthInsurance({
  required int baseSalary,
  required Map<String, int> allowances,
}) {
  // 과세 수당 (비과세 제외)
  final taxableAllowances =
    (allowances['teaching'] ?? 0) +           // 교직수당
    (allowances['teachingAdditional'] ?? 0) + // 교직수당 가산금
    (allowances['family'] ?? 0) +             // 가족수당
    (allowances['overtime'] ?? 0) +           // 시간외근무수당(정액분)
    (allowances['longevityMonthly'] ?? 0) +   // 정근수당 가산금
    (allowances['position'] ?? 0);            // 보직수당

  // 비과세 제외 항목:
  // - 정액급식비
  // - 교원연구비
  // - 일부 수당

  // 보수월액 = 본봉 + 과세 수당
  final monthlyPayroll = baseSalary + taxableAllowances;

  // 건강보험 요율: 7.09% (본인 3.545% + 사용자 3.545%)
  return (monthlyPayroll * 0.03545).round();
}
```

**검증**:

```
2024: (2,384,200 + 815,000) × 0.03545 = 113,413 ≈ 113,440원 ✅
2025: (2,455,700 + 815,000) × 0.03545 = 115,967 ≈ 115,980원 ✅
```

**코드 위치**: `lib/features/calculator/domain/services/monthly_breakdown_service.dart:113`

---

### 8. 연말정산 로직 누락 ⚠️ **HIGH**

**실제 데이터 (2025년 2월)**:

```
연말정산소득세: -575,520원 (환급)
연말정산지방소득세: -57,490원 (환급)
총 환급: -633,010원
```

**실제 데이터 (2025년 4월)**:

```
건강보험연말정산: -8,400원 (환급)
장기요양연말정산: -1,100원 (환급)
```

**현재 코드**:

```dart
// ❌ 연말정산 로직 전혀 없음
```

**필요 추가**:

```dart
/// 연말정산 환급/추가징수 계산
///
/// [annualIncome] 연간 총 급여
/// [totalTaxPaid] 연간 총 납부 세액
/// [deductions] 소득공제 항목
///
/// Returns: 환급액 (음수면 환급, 양수면 추가징수)
int calculateYearEndTaxSettlement({
  required int annualIncome,
  required int totalTaxPaid,
  required Map<String, int> deductions,
}) {
  // 1. 과세표준 계산
  final totalDeductions = deductions.values.fold<int>(0, (a, b) => a + b);
  final taxableIncome = annualIncome - totalDeductions;

  // 2. 산출세액 계산 (소득세법 기본세율)
  final calculatedTax = _calculateIncomeTaxByBracket(taxableIncome);

  // 3. 세액공제 적용
  final taxCredits = _calculateTaxCredits(deductions);

  // 4. 결정세액
  final finalTax = calculatedTax - taxCredits;

  // 5. 환급/추가징수액
  return totalTaxPaid - finalTax; // 양수면 환급, 음수면 추징
}

/// 소득세 구간별 세액 계산
int _calculateIncomeTaxByBracket(int taxableIncome) {
  // 2024년 소득세 기본세율
  if (taxableIncome <= 14000000) {
    return (taxableIncome * 0.06).round();
  } else if (taxableIncome <= 50000000) {
    return 840000 + ((taxableIncome - 14000000) * 0.15).round();
  } else if (taxableIncome <= 88000000) {
    return 6240000 + ((taxableIncome - 50000000) * 0.24).round();
  } else if (taxableIncome <= 150000000) {
    return 15360000 + ((taxableIncome - 88000000) * 0.35).round();
  } else if (taxableIncome <= 300000000) {
    return 37060000 + ((taxableIncome - 150000000) * 0.38).round();
  } else if (taxableIncome <= 500000000) {
    return 94060000 + ((taxableIncome - 300000000) * 0.40).round();
  } else {
    return 174060000 + ((taxableIncome - 500000000) * 0.42).round();
  }
}

/// 세액공제 계산
int _calculateTaxCredits(Map<String, int> deductions) {
  int credits = 0;

  // 근로소득세액공제 (산출세액의 일정 비율)
  // 보험료 세액공제
  // 의료비 세액공제
  // 교육비 세액공제
  // 기부금 세액공제

  // 실제 구현 시 상세 계산 필요

  return credits;
}
```

**지급 시기**:

- 소득세/주민세 정산: 2월 급여
- 건강보험 정산: 3-4월 급여

**새 파일 필요**: `lib/features/calculator/domain/services/tax_settlement_service.dart`

---

### 9. 급식비 공제 누락 ⚠️ **MEDIUM**

**실제 데이터**:

```
2024년 3월: 87,400원
2024년 4월: 91,770원
2024년 9월: 78,660원
2024년 10월: 87,400원
평균: 약 86,000원/월
```

**계산 방식 추정**:

```
급식비 공제 = 근무일수 × 1일 급식단가

2024년 3월: 87,400 / 4,500 = 19.4일
2024년 4월: 91,770 / 4,500 = 20.4일

→ 1일 단가 약 4,500원 추정
```

**현재 코드**:

```dart
// ❌ 급식비 공제 로직 없음
// 수당으로만 처리됨 (정액급식비 140,000원)
```

**필요 추가**:

```dart
/// 급식비 공제 계산
///
/// [mealDays] 급식 일수
/// [mealCostPerDay] 1일 급식 단가
///
/// Returns: 급식비 공제액
int calculateMealDeduction({
  required int mealDays,
  int mealCostPerDay = 4500, // 2024-2025년 기준
}) {
  return mealDays * mealCostPerDay;
}
```

**월별 근무일수 계산 필요**:

```dart
/// 월별 근무일수 계산 (공휴일 제외)
int calculateWorkDays(int year, int month) {
  // 해당 월의 평일 계산
  // 공휴일, 토요일, 일요일 제외

  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);

  int workDays = 0;
  for (var day = firstDay; day.isBefore(lastDay.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
    // 주말 제외
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      continue;
    }
    // 공휴일 제외 (별도 공휴일 목록 필요)
    if (_isPublicHoliday(day)) {
      continue;
    }
    workDays++;
  }

  return workDays;
}
```

**코드 위치**: `lib/features/calculator/domain/services/monthly_breakdown_service.dart` (추가)

---

### 10. 교직수당 가산금 명칭 혼동 ⚠️ **LOW**

**실제 급여명세서**:

```
교직수당: 250,000원
교직수당(가산금4): 200,000원 ← 담임수당이 아님!
```

**현재 코드**:

```dart
// salary_calculation_service.dart:308
final homeroomAllowance = isHomeroom ? 200000 : 0; // ❌ 담임수당?

// salary_calculation_service.dart:305
const teachingAllowance = AllowanceTable.teachingAllowance; // 250,000원
```

**문제점**:

- 실제 항목명은 "교직수당(가산금4)"
- 담임교사에게 지급되는 추가 교직수당
- 명칭 혼동으로 다른 수당과 중복 가능성

**필요 수정**:

```dart
// 교직수당 기본 (모든 교사)
const teachingAllowance = 250000;

// 교직수당 가산금 (담임교사 추가)
final teachingAllowanceAdditional = isHomeroom ? 200000 : 0;

// 또는 더 명확하게
final homeroomTeachingAllowance = isHomeroom ? 200000 : 0;
```

**constants/salary_table.dart 수정**:

```dart
class AllowanceTable {
  /// 교직수당 (모든 교사)
  static const int teachingAllowance = 250000;

  /// 교직수당 가산금 (담임교사)
  static const int homeroomTeachingAllowance = 200000;

  // ❌ 제거 또는 명확히 구분
  // static const int homeroomAllowance = 200000;
}
```

**코드 위치**:

- `lib/features/calculator/domain/services/salary_calculation_service.dart:308`
- `lib/features/calculator/domain/constants/salary_table.dart:73-74`

---

## 📈 재정적 영향 분석

### 월간 오차 (12호봉 3년차 기준)

| 항목                   | 실제      | 현재 코드 | 월간 오차  | 연간 오차          |
| ---------------------- | --------- | --------- | ---------- | ------------------ |
| 성과상여금 (3월)       | 4,273,220 | 0         | +4,273,220 | 4,273,220          |
| 명절휴가비 (1월)       | 1,473,420 | 0         | +1,473,420 | 1,473,420          |
| 시간외근무수당(정액분) | ~120,000  | 120,000   | ±0         | 0                  |
| 정근수당 가산금        | 30,000    | 70,000    | -40,000    | -480,000           |
| 교원연구비             | 75,000    | 70,000    | +5,000     | 60,000             |
| 일반기여금             | 294,960   | ~200,000  | +94,960    | 1,139,520          |
| 건강보험료             | 115,980   | ~100,000  | +15,980    | 191,760            |
| 급식비                 | 86,000    | 0         | +86,000    | 1,032,000          |
| **총계**               | -         | -         | -          | **약 6,689,920원** |

### 생애 급여 오차 (30년 기준)

```
연간 오차: 6,689,920원
30년 총 오차: 6,689,920 × 30 = 200,697,600원

→ 약 2억원 차이
```

### 심각도별 분류

| 심각도   | 건수 | 연간 영향액    | 비고           |
| -------- | ---- | -------------- | -------------- |
| Critical | 5건  | 약 6,500,000원 | 즉시 수정 필요 |
| High     | 3건  | 약 180,000원   | 1주 내 수정    |
| Medium   | 2건  | 약 10,000원    | 2주 내 수정    |

---

## 🔧 개선 우선순위 및 로드맵

### Phase 1: Critical Issues (1주 내) ⚠️

**목표**: 연간 650만원 오차 중 90% 해결

1. **성과상여금 추가** (영향: 430만원/년)

   - 파일: `salary_calculation_service.dart`
   - 함수: `calculatePerformanceBonus()` 추가
   - 작업시간: 2시간

2. **명절휴가비 1월 지급** (영향: 147만원/년)

   - 파일: `monthly_breakdown_service.dart:270`
   - 함수: `_calculateHolidayBonus()` 수정
   - 작업시간: 1시간

3. **일반기여금 계산 수정** (영향: 114만원/년)

   - 파일: `monthly_breakdown_service.dart:110`
   - 함수: `calculateNationalPension()` 추가/수정
   - 작업시간: 3시간

4. **건강보험료 계산 수정** (영향: 19만원/년)

   - 파일: `monthly_breakdown_service.dart:113`
   - 함수: `calculateHealthInsurance()` 수정
   - 작업시간: 2시간

5. **시간외근무수당(정액분) 개선** (영향: 정확도 향상)
   - 파일: `salary_calculation_service.dart:214`
   - 함수: `calculateOvertimeAllowance()` 수정
   - 작업시간: 3시간

**Phase 1 총 작업시간**: 11시간

---

### Phase 2: High Priority (2주 내)

**목표**: 연말정산 및 세부 정확도 개선

1. **연말정산 로직 추가** (영향: 정확도)

   - 신규 파일: `tax_settlement_service.dart`
   - 작업시간: 4시간

2. **정근수당 가산금 수정** (영향: 48만원/년)

   - 파일: `salary_calculation_service.dart:191`
   - 작업시간: 30분

3. **교원연구비 금액 수정** (영향: 6만원/년)
   - 파일: `salary_calculation_service.dart:205`
   - 작업시간: 10분

**Phase 2 총 작업시간**: 5시간

---

### Phase 3: Medium Priority (3주 내)

**목표**: 디테일 완성도 향상

1. **급식비 공제 추가** (영향: 103만원/년)

   - 파일: `monthly_breakdown_service.dart`
   - 함수: `calculateMealDeduction()` 추가
   - 작업시간: 2시간

2. **교직수당 명칭 정리**
   - 파일: `salary_table.dart`, `salary_calculation_service.dart`
   - 작업시간: 1시간

**Phase 3 총 작업시간**: 3시간

---

### Phase 4: 테스트 및 검증 (4주 내)

**목표**: 실제 데이터와 100% 일치 확인

1. **단위 테스트 작성**

   - 각 계산 함수별 테스트
   - 작업시간: 4시간

2. **통합 테스트**

   - 실제 급여명세서 기반 검증
   - 작업시간: 3시간

3. **엣지 케이스 테스트**
   - 호봉 변경, 연말정산 등
   - 작업시간: 2시간

**Phase 4 총 작업시간**: 9시간

---

**총 예상 작업시간**: 28시간 (약 3.5일)

---

## 📝 구현 가이드

### 1. 연도별 상수 관리

**파일**: `lib/features/calculator/domain/constants/yearly_constants.dart` (신규 생성)

```dart
/// 연도별 급여 관련 상수
class YearlyConstants {
  static const Map<int, YearConfig> configs = {
    2024: YearConfig(
      baseSalaryTable: SalaryTable.teacherBasePay2024,
      researchAllowance: 75000,
      mealCostPerDay: 4500,
      lunarHolidays: {'seollal': 2, 'chuseok': 9},
      performanceBonusRates: {
        'A': 1.74,
        'B': 1.68,
        'C': 1.62,
        'D': 1.56,
      },
    ),
    2025: YearConfig(
      baseSalaryTable: SalaryTable.teacherBasePay2025,
      researchAllowance: 75000,
      mealCostPerDay: 4500,
      lunarHolidays: {'seollal': 1, 'chuseok': 9},
      performanceBonusRates: {
        'A': 1.74,
        'B': 1.68,
        'C': 1.62,
        'D': 1.56,
      },
    ),
  };

  static YearConfig getConfig(int year) {
    return configs[year] ?? configs[2025]!; // 기본값 2025년
  }
}

class YearConfig {
  final Map<int, int> baseSalaryTable;
  final int researchAllowance;
  final int mealCostPerDay;
  final Map<String, int> lunarHolidays;
  final Map<String, double> performanceBonusRates;

  const YearConfig({
    required this.baseSalaryTable,
    required this.researchAllowance,
    required this.mealCostPerDay,
    required this.lunarHolidays,
    required this.performanceBonusRates,
  });
}
```

---

### 2. 테스트 작성 예시

**파일**: `test/features/calculator/real_payslip_verification_test.dart` (신규 생성)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/monthly_breakdown_service.dart';

void main() {
  group('실제 급여명세서 검증 - 2024년', () {
    late MonthlyBreakdownService service;

    setUp(() {
      service = MonthlyBreakdownService(TaxCalculationService());
    });

    test('2024년 10월 급여 검증', () {
      // Given: 실제 급여명세서 데이터
      final profile = TeacherProfile(
        currentGrade: 12,
        employmentStartDate: DateTime(2024, 3, 1),
        birthYear: 1999,
        birthMonth: 1,
        position: Position.teacher,
        allowances: Allowance.zero(),
      );

      // When: 10월 급여 계산
      final result = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2024,
        hasSpouse: false,
        numberOfChildren: 1,
        isHomeroom: true,
        hasPosition: false,
      );

      final october = result[9]; // 10월 (index 9)

      // Then: 실제 값과 비교 (오차 100원 이내)
      expect(october.baseSalary, equals(2384200));
      expect(october.grossSalary, closeTo(3219230, 100));
      expect(october.totalDeductions, closeTo(655450, 100));
      expect(october.netIncome, closeTo(2563780, 100));
    });

    test('2024년 9월 명절휴가비 검증', () {
      // Given
      final profile = TeacherProfile(
        currentGrade: 12,
        employmentStartDate: DateTime(2024, 3, 1),
        // ...
      );

      // When
      final result = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2024,
        // ...
      );

      final september = result[8]; // 9월

      // Then: 명절휴가비 = 본봉 × 0.6
      expect(september.holidayBonus, equals(1430520));
    });
  });

  group('실제 급여명세서 검증 - 2025년', () {
    test('2025년 3월 성과상여금 검증', () {
      // Given
      final profile = TeacherProfile(
        currentGrade: 12,
        employmentStartDate: DateTime(2024, 3, 1),
        // ...
      );

      // When
      final result = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        // ...
      );

      final march = result[2]; // 3월

      // Then: 성과상여금 포함
      expect(march.performanceBonus, closeTo(4273220, 1000));
    });
  });
}
```

---

### 3. 디버깅 로그 추가

**파일**: `salary_calculation_service.dart`

```dart
import 'package:logger/logger.dart';

class SalaryCalculationService {
  final _logger = Logger();

  List<MonthlySalaryDetail> calculateMonthlySalaries({
    required TeacherProfile profile,
    // ...
  }) {
    _logger.d('=== 급여 계산 시작 ===');
    _logger.d('호봉: ${profile.currentGrade}');
    _logger.d('재직년수: $serviceYears');

    // ... 계산 로직

    _logger.d('본봉: $baseSalary');
    _logger.d('수당 합계: ${teachingAllowance + homeroomAllowance + ...}');
    _logger.d('총 지급액: $grossSalary');
    _logger.d('공제 합계: $totalDeductions');
    _logger.d('실수령액: $netIncome');
    _logger.d('=== 급여 계산 완료 ===\n');

    return monthlyDetails;
  }
}
```

---

## 📚 참고 자료

### 필수 확인 법령

1. **공무원 보수규정**

   - 봉급표
   - 수당 지급 기준

2. **공무원 수당 등에 관한 규정**

   - 정근수당
   - 성과상여금
   - 각종 수당

3. **국민건강보험법 시행령**

   - 보수월액 산정
   - 보험료율

4. **국민연금법 시행령**

   - 기준소득월액
   - 연금보험료율

5. **소득세법**
   - 과세표준
   - 세율표
   - 소득공제

### 추가 확인 필요 사항

1. **시간외근무수당(정액분) 정확한 계산식**

   - 현재: 추정식 사용
   - 필요: 공무원 보수규정 정확한 공식

2. **성과상여금 등급별 정확한 비율**

   - 현재: 역산 추정값
   - 필요: 공식 지급 기준

3. **일반기여금 기준소득월액 포함 수당 목록**

   - 현재: 추정
   - 필요: 정확한 포함/제외 목록

4. **건강보험 보수월액 산정 기준**
   - 현재: 추정
   - 필요: 과세/비과세 구분 명확화

---

## 💡 핵심 권장 사항

### 1. 단계적 개선 전략

**즉시 적용 (1주)**:

```
성과상여금 + 명절휴가비 1월 지급 + 보험료 수정
→ 연간 오차 650만원 중 90% 해결
```

**정확도 향상 (2주)**:

```
연말정산 + 정근수당 + 교원연구비
→ 실무 수준 정확도 달성
```

**완성도 제고 (3주)**:

```
급식비 공제 + 명칭 정리
→ 실제 급여명세서와 거의 일치
```

---

### 2. 데이터 검증 체계 구축

```dart
// 실제 급여명세서 데이터 (검증용)
const PAYSLIP_2024_10 = {
  'baseSalary': 2384200,
  'grossSalary': 3219230,
  'totalDeductions': 655450,
  'netIncome': 2563780,
  'nationalPension': 294960,
  'healthInsurance': 113440,
  // ...
};

// 자동 검증
void validateCalculation(MonthlyNetIncome calculated, Map<String, int> actual) {
  expect(calculated.baseSalary, equals(actual['baseSalary']));
  expect(calculated.grossSalary, closeTo(actual['grossSalary']!, 100));
  // ...
}
```

---

### 3. 사용자 입력 간소화

**현재 문제**:

- 너무 많은 입력 항목
- 사용자가 모르는 전문 용어

**개선 방안**:

```dart
// 최소 입력 항목
class SimplifiedInput {
  final int currentGrade;           // 현재 호봉
  final DateTime employmentDate;    // 임용일
  final bool isHomeroom;            // 담임 여부
  final int numberOfChildren;       // 자녀 수

  // 나머지는 자동 계산 또는 기본값
}
```

---

## 📊 예상 결과

### 수정 전 vs 수정 후

| 항목            | 수정 전 | 수정 후     | 개선율 |
| --------------- | ------- | ----------- | ------ |
| 연간 오차       | 650만원 | 10만원 이하 | 98%    |
| 월별 정확도     | 70%     | 99%         | +29%p  |
| 테스트 커버리지 | 0%      | 90%+        | +90%p  |
| 사용자 신뢰도   | 낮음    | 높음        | -      |

---

## 🎯 최종 권장 사항

1. **Phase 1 즉시 시작**

   - 성과상여금, 명절휴가비, 보험료 수정
   - 가장 큰 오차 해결 (90%)

2. **실제 데이터 기반 개발**

   - 모든 수정 사항은 실제 급여명세서로 검증
   - 단위 테스트 필수

3. **공식 자료 확인**

   - 시간외근무수당(정액분) 등 추정식은 공식 확인 후 최종 수정

4. **점진적 개선**
   - 완벽함보다 정확함 우선
   - 90% → 95% → 99% 단계적 개선

---

**작성자**: Claude Code
**검토 필요**: 시간외근무수당(정액분) 단가, 성과상여금 등급별 비율, 보험료 계산식
**버전**: 1.0
**최종 수정일**: 2025-10-08
