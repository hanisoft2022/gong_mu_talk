import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lounge_model.dart';

/// Lounge 정의 JSON 로더
///
/// lounge_definitions.dart (1,897 lines)를 JSON으로 분리하여
/// 토큰 사용량 절감 및 유지보수성 향상
///
/// Usage:
/// ```dart
/// // In bootstrap:
/// await LoungeLoader.init();
///
/// // Anywhere in app (after init):
/// final lounges = LoungeLoader.lounges;
/// ```
class LoungeLoader {
  LoungeLoader._();

  static List<Lounge>? _cachedLounges;

  /// 초기화 (앱 시작 시 호출 필수)
  ///
  /// bootstrap.dart에서 호출하여 lounges를 미리 로드
  static Future<void> init() async {
    await _loadLounges();
  }

  /// Lounge 목록 sync getter
  ///
  /// init() 호출 후에만 사용 가능
  /// 초기화되지 않았으면 StateError 발생
  static List<Lounge> get lounges {
    if (_cachedLounges == null) {
      throw StateError(
        'LoungeLoader not initialized. Call LoungeLoader.init() in bootstrap.',
      );
    }
    return _cachedLounges!;
  }

  /// JSON에서 Lounge 목록 로드 (내부용)
  static Future<void> _loadLounges() async {
    if (_cachedLounges != null) {
      return; // Already loaded
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/lounges.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final loungesJson = jsonData['lounges'] as List<dynamic>;

      _cachedLounges = loungesJson
          .map((json) => LoungeFromJson.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load lounges: $e');
    }
  }

  /// 캐시 초기화 (테스트용)
  static void clearCache() {
    _cachedLounges = null;
  }
}

/// Lounge JSON 파싱 확장
extension LoungeFromJson on Lounge {
  static Lounge fromJson(Map<String, dynamic> json) {
    return Lounge(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      shortName: json['shortName'] as String,
      type: _parseLoungeType(json['type'] as String),
      accessType: _parseAccessType(json['accessType'] as String),
      requiredCareerIds: (json['requiredCareerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      parentLoungeId: json['parentLoungeId'] as String?,
      memberCount: json['memberCount'] as int,
      description: json['description'] as String,
      order: json['order'] as int,
    );
  }

  static LoungeType _parseLoungeType(String type) {
    switch (type) {
      case 'all':
        return LoungeType.all;
      case 'category':
        return LoungeType.category;
      case 'specific':
        return LoungeType.specific;
      default:
        throw ArgumentError('Unknown LoungeType: $type');
    }
  }

  static LoungeAccessType _parseAccessType(String accessType) {
    switch (accessType) {
      case 'public':
        return LoungeAccessType.public;
      case 'careerOnly':
        return LoungeAccessType.careerOnly;
      default:
        throw ArgumentError('Unknown LoungeAccessType: $accessType');
    }
  }
}
