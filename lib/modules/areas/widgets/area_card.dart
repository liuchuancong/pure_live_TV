import 'package:pure_live/common/index.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AreaCard extends StatefulWidget {
  const AreaCard({super.key, required this.category});
  final LiveArea category;

  @override
  State<AreaCard> createState() => _AreaCardState();
}

// id: widget.category.areaId!, siteTitle: widget.category.areaName!, siteUrl: widget.category.areaType!, siteIsHot: 0)
class _AreaCardState extends State<AreaCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(7.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () {
          if (widget.category.platform == 'iptv') {
            var roomItem = LiveRoom(
              roomId: widget.category.areaId,
              title: widget.category.typeName,
              cover: '',
              nick: widget.category.areaName,
              watching: '',
              avatar:
                  'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
              area: '',
              liveStatus: LiveStatus.live,
              status: true,
              platform: 'iptv',
            );
            AppNavigator.toLiveRoomDetail(liveRoom: roomItem);
          } else {
            AppNavigator.toCategoryDetail(site: Sites.of(widget.category.platform!), category: widget.category);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                margin: const EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                elevation: 0,
                child: CachedNetworkImage(
                  imageUrl: widget.category.areaPic!,
                  cacheManager: CustomCacheManager.instance,
                  fit: BoxFit.fill,
                  errorWidget: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.live_tv_rounded,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: Text(
                widget.category.areaName!,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.category.typeName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
