/// Nickname validation utility
///
/// Validation rules:
/// 1. Length: 2-8 chars (Korean), 2-16 chars (English)
/// 2. Allowed: Korean, English, Numbers, Underscore(_)
/// 3. Forbidden: Spaces, Special chars (except _), Emojis
/// 4. No consecutive special chars (__)
/// 5. No leading/trailing special chars
/// 6. No numbers-only nicknames
/// 7. No banned words
library;

import '../constants/banned_words.dart';

class NicknameValidator {
  NicknameValidator._();

  // ===== Constants =====
  static const int minLength = 2;
  static const int maxLengthKorean = 8;
  static const int maxLengthEnglish = 16;

  // ===== Regular Expressions =====
  // 한글: ㄱ-ㅎ, ㅏ-ㅣ, 가-힣
  static final _koreanRegex = RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]');
  // 영문: a-z, A-Z
  static final _englishRegex = RegExp(r'[a-zA-Z]');
  // 숫자: 0-9
  static final _numberRegex = RegExp(r'[0-9]');
  // 허용 문자: 한글 + 영문 + 숫자 + _
  static final _allowedCharsRegex = RegExp(r'^[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9_]+$');
  // 숫자만
  static final _numbersOnlyRegex = RegExp(r'^[0-9]+$');
  // 연속 언더스코어
  static final _consecutiveUnderscoreRegex = RegExp(r'__');

  // ===== Validation Results =====
  static NicknameValidationResult validate(String nickname) {
    // 1. 빈 문자열 체크
    if (nickname.isEmpty) {
      return NicknameValidationResult.error('닉네임을 입력해주세요.');
    }

    // 2. 공백 체크
    if (nickname.contains(' ')) {
      return NicknameValidationResult.error('닉네임에 공백을 사용할 수 없습니다.');
    }

    // 3. 허용되지 않은 문자 체크
    if (!_allowedCharsRegex.hasMatch(nickname)) {
      return NicknameValidationResult.error('한글, 영문, 숫자, 언더스코어(_)만 사용 가능합니다.');
    }

    // 4. 길이 체크
    final lengthResult = _validateLength(nickname);
    if (!lengthResult.isValid) {
      return lengthResult;
    }

    // 5. 숫자만으로 구성 체크
    if (_numbersOnlyRegex.hasMatch(nickname)) {
      return NicknameValidationResult.error('숫자만으로 닉네임을 만들 수 없습니다.');
    }

    // 6. 특수문자 위치 체크
    if (nickname.startsWith('_') || nickname.endsWith('_')) {
      return NicknameValidationResult.error('닉네임은 언더스코어(_)로 시작하거나 끝날 수 없습니다.');
    }

    // 7. 연속 특수문자 체크
    if (_consecutiveUnderscoreRegex.hasMatch(nickname)) {
      return NicknameValidationResult.error('언더스코어(_)를 연속으로 사용할 수 없습니다.');
    }

    // 8. 금지 단어 체크
    final bannedWordResult = _validateBannedWords(nickname);
    if (!bannedWordResult.isValid) {
      return bannedWordResult;
    }

    return NicknameValidationResult.valid();
  }

  // ===== Private Helpers =====

  /// 길이 검증
  static NicknameValidationResult _validateLength(String nickname) {
    final length = nickname.length;

    // 최소 길이
    if (length < minLength) {
      return NicknameValidationResult.error('닉네임은 최소 $minLength자 이상이어야 합니다.');
    }

    // 한글 포함 여부 확인
    final hasKorean = _koreanRegex.hasMatch(nickname);

    if (hasKorean) {
      // 한글 포함: 최대 8자
      if (length > maxLengthKorean) {
        return NicknameValidationResult.error('한글이 포함된 닉네임은 최대 $maxLengthKorean자까지 가능합니다.');
      }
    } else {
      // 영문/숫자만: 최대 16자
      if (length > maxLengthEnglish) {
        return NicknameValidationResult.error('영문 닉네임은 최대 $maxLengthEnglish자까지 가능합니다.');
      }
    }

    return NicknameValidationResult.valid();
  }

  /// 금지 단어 검증
  static NicknameValidationResult _validateBannedWords(String nickname) {
    final lowerNickname = nickname.toLowerCase();

    // 1. 정확한 매칭
    for (final word in BannedWords.all) {
      if (lowerNickname.contains(word.toLowerCase())) {
        return NicknameValidationResult.error('사용할 수 없는 단어가 포함되어 있습니다.');
      }
    }

    // 2. 패턴 매칭
    for (final pattern in BannedWords.patterns) {
      if (pattern.hasMatch(nickname)) {
        return NicknameValidationResult.error('사용할 수 없는 단어가 포함되어 있습니다.');
      }
    }

    return NicknameValidationResult.valid();
  }

  // ===== Helper Methods =====

  /// 한글 포함 여부
  static bool containsKorean(String text) => _koreanRegex.hasMatch(text);

  /// 영문 포함 여부
  static bool containsEnglish(String text) => _englishRegex.hasMatch(text);

  /// 숫자 포함 여부
  static bool containsNumber(String text) => _numberRegex.hasMatch(text);

  /// 최대 길이 반환 (한글 포함 여부에 따라)
  static int getMaxLength(String text) {
    return containsKorean(text) ? maxLengthKorean : maxLengthEnglish;
  }
}

// ===== Validation Result =====

class NicknameValidationResult {
  const NicknameValidationResult({required this.isValid, this.errorMessage});

  factory NicknameValidationResult.valid() {
    return const NicknameValidationResult(isValid: true);
  }

  factory NicknameValidationResult.error(String message) {
    return NicknameValidationResult(isValid: false, errorMessage: message);
  }

  final bool isValid;
  final String? errorMessage;
}
