/// Test careers constants for development and testing purposes
///
/// This file contains a comprehensive list of career options for public servants
/// in Korea, used for testing the lounge access system in debug mode.
///
/// **Purpose**:
/// - Development/testing tool for career hierarchy system
/// - Used in debug mode only (kDebugMode)
/// - Helps validate lounge access permissions
///
/// **Categories**:
/// - Education Officials (교육공무원)
/// - General Administrative (일반행정직)
/// - Specialized Administrative (전문행정직)
/// - Health & Welfare (보건복지직)
/// - Public Security (공안직)
/// - Public Safety (치안/안전)
/// - Military (군인)
/// - Technical Tracks (기술직)
/// - Others (기타)

const List<Map<String, String>> testCareers = [
  // ================================
  // 교육공무원 (Education Officials)
  // ================================

  // 초등교사
  {'id': 'elementary_teacher', 'name': '🏫 초등교사'},

  // 중등교사 - 교과별
  {'id': 'secondary_math_teacher', 'name': '📐 중등수학교사'},
  {'id': 'secondary_korean_teacher', 'name': '📖 중등국어교사'},
  {'id': 'secondary_english_teacher', 'name': '🌍 중등영어교사'},
  {'id': 'secondary_science_teacher', 'name': '🔬 중등과학교사'},
  {'id': 'secondary_social_teacher', 'name': '🌏 중등사회교사'},
  {'id': 'secondary_arts_teacher', 'name': '🎨 중등예체능교사'},

  // 유치원/특수교육교사
  {'id': 'kindergarten_teacher', 'name': '👶 유치원교사'},
  {'id': 'special_education_teacher', 'name': '🤝 특수교육교사'},

  // 비교과 교사
  {'id': 'counselor_teacher', 'name': '💬 상담교사'},
  {'id': 'health_teacher', 'name': '🏥 보건교사'},
  {'id': 'librarian_teacher', 'name': '📚 사서교사'},
  {'id': 'nutrition_teacher', 'name': '🍎 영양교사'},

  // ================================
  // 일반행정직 (General Administrative)
  // ================================

  // 국가직
  {'id': 'admin_9th_national', 'name': '📋 9급 국가행정직'},
  {'id': 'admin_7th_national', 'name': '📊 7급 국가행정직'},
  {'id': 'admin_5th_national', 'name': '💼 5급 국가행정직'},

  // 지방직
  {'id': 'admin_9th_local', 'name': '📋 9급 지방행정직'},
  {'id': 'admin_7th_local', 'name': '📊 7급 지방행정직'},
  {'id': 'admin_5th_local', 'name': '💼 5급 지방행정직'},

  // 세무·관세
  {'id': 'tax_officer', 'name': '💰 세무직'},
  {'id': 'customs_officer', 'name': '🛃 관세직'},

  // ================================
  // 전문행정직 (Specialized Administrative)
  // ================================

  {'id': 'job_counselor', 'name': '💼 고용노동직'},
  {'id': 'statistics_officer', 'name': '📊 통계직'},
  {'id': 'librarian', 'name': '📖 사서직'},
  {'id': 'auditor', 'name': '🔍 감사직'},
  {'id': 'security_officer', 'name': '🔐 방호직'},

  // ================================
  // 보건복지직 (Health & Welfare)
  // ================================

  {'id': 'public_health_officer', 'name': '🏥 보건직'},
  {'id': 'medical_technician', 'name': '🔬 의료기술직'},
  {'id': 'nurse', 'name': '💉 간호직'},
  {'id': 'medical_officer', 'name': '⚕️ 의무직'},
  {'id': 'pharmacist', 'name': '💊 약무직'},
  {'id': 'food_sanitation', 'name': '🍽️ 식품위생직'},
  {'id': 'social_worker', 'name': '🤲 사회복지직'},

  // ================================
  // 공안직 (Public Security)
  // ================================

  {'id': 'correction_officer', 'name': '⚖️ 교정직'},
  {'id': 'probation_officer', 'name': '👁️ 보호직'},
  {'id': 'prosecution_officer', 'name': '⚖️ 검찰직'},
  {'id': 'drug_investigation_officer', 'name': '🔬 마약수사직'},
  {'id': 'immigration_officer', 'name': '🛂 출입국관리직'},
  {'id': 'railroad_police', 'name': '🚄 철도경찰직'},
  {'id': 'security_guard', 'name': '🛡️ 경위직'},

  // ================================
  // 치안/안전 (Public Safety)
  // ================================

  {'id': 'police', 'name': '👮‍♂️ 경찰관'},
  {'id': 'firefighter', 'name': '👨‍🚒 소방관'},
  {'id': 'coast_guard', 'name': '🌊 해양경찰'},

  // ================================
  // 군인 (Military)
  // ================================

  {'id': 'army', 'name': '🪖 육군'},
  {'id': 'navy', 'name': '⚓ 해군'},
  {'id': 'air_force', 'name': '✈️ 공군'},
  {'id': 'military_civilian', 'name': '🎖️ 군무원'},

  // ================================
  // 기술직 (Technical Tracks)
  // ================================

  // 공업직 (대표)
  {'id': 'mechanical_engineer', 'name': '⚙️ 기계직'},
  {'id': 'electrical_engineer', 'name': '⚡ 전기직'},
  {'id': 'electronics_engineer', 'name': '📡 전자직'},
  {'id': 'chemical_engineer', 'name': '🧪 화공직'},

  // 시설환경직 (대표)
  {'id': 'civil_engineer', 'name': '🏗️ 토목직'},
  {'id': 'architect', 'name': '🏛️ 건축직'},
  {'id': 'environmental_officer', 'name': '🌱 환경직'},

  // 농림수산직 (대표)
  {'id': 'agriculture_officer', 'name': '🌾 농업직'},
  {'id': 'fisheries_officer', 'name': '🐟 수산직'},
  {'id': 'veterinarian', 'name': '🐾 수의직'},

  // IT통신직
  {'id': 'computer_officer', 'name': '💻 전산직'},
  {'id': 'broadcasting_communication', 'name': '📺 방송통신직'},

  // 관리운영직
  {'id': 'facility_management', 'name': '🏢 시설관리직'},
  {'id': 'sanitation_worker', 'name': '🧹 위생직'},
  {'id': 'cook', 'name': '👨‍🍳 조리직'},

  // ================================
  // 기타 직렬 (Others)
  // ================================

  {'id': 'postal_service', 'name': '📮 우정직'},
  {'id': 'researcher', 'name': '🔬 연구직'},

  // ================================
  // Fallback / Reset
  // ================================

  {'id': 'none', 'name': '❌ 직렬 없음 (기본)'},
];
