enum CareerTrack {
  none,
  teacher,
  police,
  educationAdmin,
  firefighter,
  lawmaker,
  publicAdministration,
  customs,
  itSpecialist,
}

extension CareerTrackX on CareerTrack {
  String get displayName {
    switch (this) {
      case CareerTrack.none:
        return '선택 안 함';
      case CareerTrack.teacher:
        return '교사';
      case CareerTrack.police:
        return '경찰';
      case CareerTrack.educationAdmin:
        return '교육행정직';
      case CareerTrack.firefighter:
        return '소방';
      case CareerTrack.lawmaker:
        return '국회의원';
      case CareerTrack.publicAdministration:
        return '행정직';
      case CareerTrack.customs:
        return '관세직';
      case CareerTrack.itSpecialist:
        return '정보화전문직';
    }
  }

  String get emoji {
    switch (this) {
      case CareerTrack.none:
        return '🤝';
      case CareerTrack.teacher:
        return '📚';
      case CareerTrack.police:
        return '🚓';
      case CareerTrack.educationAdmin:
        return '🏫';
      case CareerTrack.firefighter:
        return '🚒';
      case CareerTrack.lawmaker:
        return '🏛️';
      case CareerTrack.publicAdministration:
        return '🗂️';
      case CareerTrack.customs:
        return '🛃';
      case CareerTrack.itSpecialist:
        return '💻';
    }
  }
}
