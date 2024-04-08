class M3uItem {
  int duration;

  String title;

  String groupTitle;

  Map<String, String> attributes;

  String link;

  M3uItem(
      {required this.duration,
      required this.title,
      this.groupTitle = '',
      Map<String, String>? attributes,
      this.link = ''})
      : attributes = attributes ?? {};

  factory M3uItem.fromItem(M3uItem item, String link) => M3uItem(
      duration: item.duration,
      title: item.title,
      groupTitle: item.groupTitle,
      attributes: item.attributes,
      link: link);
}
