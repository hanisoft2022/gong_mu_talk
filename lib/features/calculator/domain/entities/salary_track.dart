enum SalaryTrack { general, teacher }

extension SalaryTrackX on SalaryTrack {
  String get id {
    switch (this) {
      case SalaryTrack.general:
        return 'general';
      case SalaryTrack.teacher:
        return 'teacher';
    }
  }

  String get label {
    switch (this) {
      case SalaryTrack.general:
        return '일반직 공무원';
      case SalaryTrack.teacher:
        return '교원';
    }
  }
}
