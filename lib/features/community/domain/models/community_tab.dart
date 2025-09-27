enum CommunityTab {
  all('전체', 'all'),
  serial('직렬별', 'serial'),
  hot('인기', 'hot');

  const CommunityTab(this.displayName, this.value);

  final String displayName;
  final String value;

  static CommunityTab fromString(String value) {
    return CommunityTab.values.firstWhere(
      (tab) => tab.value == value,
      orElse: () => CommunityTab.all,
    );
  }
}
