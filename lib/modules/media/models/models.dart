/// The bilibili response models shared by the music and video modes — one
/// folder per model, `@freezed` (+ json_serializable where the JSON shape is
/// flat enough for codegen; the adversarial shapes keep a hand-written
/// parser next to the generated constructor). `json_converters.dart` holds
/// the lenient scalar handling the web API's answers need.
library;

export 'json_converters.dart';
export 'comment_item/comment_item.dart';
export 'dynamic_video/dynamic_video.dart';
export 'fav_folder/fav_folder.dart';
export 'fav_resource/fav_resource.dart';
export 'history_item/history_item.dart';
export 'hotword/hotword.dart';
export 'music_archive/music_archive.dart';
export 'music_part/music_part.dart';
export 'music_play_mode/music_play_mode.dart';
export 'music_play_urls/music_play_urls.dart';
export 'music_stream_option/music_stream_option.dart';
export 'music_track/music_track.dart';
export 'music_up/music_up.dart';
export 'pgc_episode/pgc_episode.dart';
export 'pgc_item/pgc_item.dart';
export 'pgc_season/pgc_season.dart';
export 'search_live_item/search_live_item.dart';
export 'search_pgc_item/search_pgc_item.dart';
export 'search_user_item/search_user_item.dart';
export 'subtitle_cue/subtitle_cue.dart';
export 'subtitle_track/subtitle_track.dart';
export 'to_view_item/to_view_item.dart';
export 'ugc_my_info/ugc_my_info.dart';
export 'user_space_info/user_space_info.dart';
