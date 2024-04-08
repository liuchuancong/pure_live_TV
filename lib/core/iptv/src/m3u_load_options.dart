class M3uLoadOptions {
  String groupTitleField;
  String wrongItemTitle;

  M3uLoadOptions({String? groupTitleField, String? wrongItemTitle})
      : groupTitleField = groupTitleField ?? 'group-title',
        wrongItemTitle = wrongItemTitle ?? 'Unknown';
}
