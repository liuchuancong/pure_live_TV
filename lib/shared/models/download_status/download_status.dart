import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.none)
enum DownloadState {
  @JsonValue('notDownloaded')
  notDownloaded,
  @JsonValue('downloading')
  downloading,
  @JsonValue('downloaded')
  downloaded;

  bool get isNotDownloaded => this == DownloadState.notDownloaded;
  bool get isDownloading => this == DownloadState.downloading;
  bool get isDownloaded => this == DownloadState.downloaded;
}
