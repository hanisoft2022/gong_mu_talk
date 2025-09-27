enum LoungeScope { all, serial }

enum LoungeSort { latest, popular, likes }

extension LoungeSortLabel on LoungeSort {
  String get label {
    switch (this) {
      case LoungeSort.latest:
        return '최신순';
      case LoungeSort.popular:
        return '오늘의 인기순';
      case LoungeSort.likes:
        return '오늘의 좋아요순';
    }
  }
}
