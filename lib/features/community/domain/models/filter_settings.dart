import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';

class FilterSettings extends Equatable {
  const FilterSettings({
    this.allowedSerials = const [],
    this.blockedSerials = const [],
    this.allowedTracks = const [],
    this.blockedTracks = const [],
    this.allowedRegions = const [],
    this.blockedRegions = const [],
    this.showOnlyVerified = false,
    this.hideAnonymous = false,
  });

  final List<String> allowedSerials;
  final List<String> blockedSerials;
  final List<CareerTrack> allowedTracks;
  final List<CareerTrack> blockedTracks;
  final List<String> allowedRegions;
  final List<String> blockedRegions;
  final bool showOnlyVerified;
  final bool hideAnonymous;

  bool get hasActiveFilters {
    return allowedSerials.isNotEmpty ||
        blockedSerials.isNotEmpty ||
        allowedTracks.isNotEmpty ||
        blockedTracks.isNotEmpty ||
        allowedRegions.isNotEmpty ||
        blockedRegions.isNotEmpty ||
        showOnlyVerified ||
        hideAnonymous;
  }

  FilterSettings copyWith({
    List<String>? allowedSerials,
    List<String>? blockedSerials,
    List<CareerTrack>? allowedTracks,
    List<CareerTrack>? blockedTracks,
    List<String>? allowedRegions,
    List<String>? blockedRegions,
    bool? showOnlyVerified,
    bool? hideAnonymous,
  }) {
    return FilterSettings(
      allowedSerials: allowedSerials ?? this.allowedSerials,
      blockedSerials: blockedSerials ?? this.blockedSerials,
      allowedTracks: allowedTracks ?? this.allowedTracks,
      blockedTracks: blockedTracks ?? this.blockedTracks,
      allowedRegions: allowedRegions ?? this.allowedRegions,
      blockedRegions: blockedRegions ?? this.blockedRegions,
      showOnlyVerified: showOnlyVerified ?? this.showOnlyVerified,
      hideAnonymous: hideAnonymous ?? this.hideAnonymous,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'allowedSerials': allowedSerials,
      'blockedSerials': blockedSerials,
      'allowedTracks': allowedTracks.map((track) => track.name).toList(),
      'blockedTracks': blockedTracks.map((track) => track.name).toList(),
      'allowedRegions': allowedRegions,
      'blockedRegions': blockedRegions,
      'showOnlyVerified': showOnlyVerified,
      'hideAnonymous': hideAnonymous,
    };
  }

  static FilterSettings fromMap(Map<String, Object?> data) {
    return FilterSettings(
      allowedSerials: (data['allowedSerials'] as List<dynamic>?)?.cast<String>() ?? [],
      blockedSerials: (data['blockedSerials'] as List<dynamic>?)?.cast<String>() ?? [],
      allowedTracks: ((data['allowedTracks'] as List<dynamic>?) ?? [])
          .cast<String>()
          .map((name) => CareerTrack.values.firstWhere(
                (track) => track.name == name,
                orElse: () => CareerTrack.none,
              ))
          .where((track) => track != CareerTrack.none)
          .toList(),
      blockedTracks: ((data['blockedTracks'] as List<dynamic>?) ?? [])
          .cast<String>()
          .map((name) => CareerTrack.values.firstWhere(
                (track) => track.name == name,
                orElse: () => CareerTrack.none,
              ))
          .where((track) => track != CareerTrack.none)
          .toList(),
      allowedRegions: (data['allowedRegions'] as List<dynamic>?)?.cast<String>() ?? [],
      blockedRegions: (data['blockedRegions'] as List<dynamic>?)?.cast<String>() ?? [],
      showOnlyVerified: data['showOnlyVerified'] as bool? ?? false,
      hideAnonymous: data['hideAnonymous'] as bool? ?? false,
    );
  }

  static const FilterSettings empty = FilterSettings();

  @override
  List<Object?> get props => [
        allowedSerials,
        blockedSerials,
        allowedTracks,
        blockedTracks,
        allowedRegions,
        blockedRegions,
        showOnlyVerified,
        hideAnonymous,
      ];
}

// Korean regions/cities commonly used by civil servants
class KoreanRegions {
  static const Map<String, List<String>> regions = {
    '서울특별시': [
      '강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구',
      '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구',
      '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구'
    ],
    '부산광역시': [
      '강서구', '금정구', '기장군', '남구', '동구', '동래구', '부산진구', '북구',
      '사상구', '사하구', '서구', '수영구', '연제구', '영도구', '중구', '해운대구'
    ],
    '대구광역시': [
      '남구', '달서구', '달성군', '동구', '북구', '서구', '수성구', '중구'
    ],
    '인천광역시': [
      '강화군', '계양구', '남동구', '동구', '미추홀구', '부평구', '서구', '연수구', '옹진군', '중구'
    ],
    '광주광역시': [
      '광산구', '남구', '동구', '북구', '서구'
    ],
    '대전광역시': [
      '대덕구', '동구', '서구', '유성구', '중구'
    ],
    '울산광역시': [
      '남구', '동구', '북구', '울주군', '중구'
    ],
    '세종특별자치시': [
      '세종시'
    ],
    '경기도': [
      '가평군', '고양시', '과천시', '광명시', '광주시', '구리시', '군포시', '김포시',
      '남양주시', '동두천시', '부천시', '성남시', '수원시', '시흥시', '안산시', '안성시',
      '안양시', '양주시', '양평군', '여주시', '연천군', '오산시', '용인시', '의왕시',
      '의정부시', '이천시', '파주시', '평택시', '포천시', '하남시', '화성시'
    ],
  };

  static List<String> getAllRegions() {
    return regions.keys.toList();
  }

  static List<String> getCitiesForRegion(String region) {
    return regions[region] ?? [];
  }
}