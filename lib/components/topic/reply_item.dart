import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ex/http/dio_web.dart';
import 'package:flutter_v2ex/utils/storage.dart';
import 'package:flutter_v2ex/utils/event_bus.dart';
import 'package:flutter_v2ex/components/common/avatar.dart';
import 'package:flutter_v2ex/components/topic/reply_new.dart';
import 'package:flutter_v2ex/models/web/item_topic_reply.dart';
import 'package:flutter_v2ex/components/topic/html_render.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ReplyListItem extends StatefulWidget {
  ReplyListItem({
    required this.reply,
    required this.topicId,
    this.queryReplyList,
    this.totalPage,
    Key? key,
  }) : super(key: key);

  final ReplyItem reply;
  final String topicId;
  final queryReplyList;
  int? totalPage;

  @override
  State<ReplyListItem> createState() => _ReplyListItemState();
}

class _ReplyListItemState extends State<ReplyListItem> {
  // bool isChoose = false;
  List<Map<dynamic, dynamic>> sheetMenu = [
    {
      'id': 3,
      'title': '复制内容',
      'leading': const Icon(
        Icons.copy_rounded,
        size: 21,
      ),
    },
    {
      'id': 6,
      'title': '自由复制',
      'leading': const Icon(
        Icons.copy_all,
        size: 21,
      ),
    },
    {
      'id': 7,
      'title': '本地保存',
      'leading': const Icon(
        Icons.save_alt_rounded,
        size: 21,
      ),
    },
    {
      'id': 4,
      'title': '忽略回复',
      'leading': const Icon(
        Icons.not_interested_rounded,
        size: 21,
      ),
    },
  ];

  ReplyItem reply = ReplyItem();
  String heroTag = Random().nextInt(999).toString();
  final GlobalKey repaintKey = GlobalKey();
  bool ignoreStatus = false; // 对当前主题的忽略状态 默认false

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 无法忽略自己的回复
    var replyUserName = widget.reply.userName;
    var loginUserName = '';
    if (GStorage().getUserInfo().isNotEmpty) {
      loginUserName = GStorage().getUserInfo()['userName'];
    }
    if (replyUserName == loginUserName) {
      setState(() {
        sheetMenu.removeAt(2);
      });
    }
    setState(() {
      reply = widget.reply;
    });
  }

  void menuAction(id) {
    switch (id) {
      case 1:
        replyComment();
        break;
      case 2:
        widget
            .queryReplyList(reply.replyMemberList, reply.floorNumber, [reply]);
        break;
      case 3:
        copyComment();
        break;
      case 4:
        ignoreComment();
        break;
      case 5:
        Get.toNamed('/member/${reply.userName}', parameters: {
          'memberAvatar': reply.avatar,
          'heroTag': reply.userName + heroTag,
        });
        break;
      case 6:
        showCopySheet();
        break;
      case 7:
        takePicture();
        break;
    }
  }

  // 回复评论
  void replyComment() {
    var replyId = reply.replyId;
    if (replyId == '') {
      // 刚回复的楼层没有回复replyId
      SmartDialog.showToast('无法回复最新评论');
      return;
    }
    showModalBottomSheet<Map>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ReplyNew(
          replyMemberList: [reply],
          topicId: widget.topicId,
          totalPage: widget.totalPage,
        );
      },
    ).then((value) => {
          if (value != null)
            {
              print('reply item EventBus'),
              eventBus.emit('topicReply', value['replyStatus'])
            }
        });
  }

  // 复制评论
  void copyComment() {
    Clipboard.setData(ClipboardData(text: reply.content));
    SmartDialog.showToast('复制成功');
  }

  // 忽略回复
  void ignoreComment() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('忽略回复'),
        content: Text.rich(TextSpan(children: [
          const TextSpan(text: '确认不再显示来自 '),
          TextSpan(
            text: '@${reply.userName}',
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const TextSpan(text: ' 的这条回复？')
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
              onPressed: () async{
                var res = await DioRequestWeb.ignoreReply(reply.replyId);
                if(res) {
                  setState(() {
                    ignoreStatus = true;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('确定')),
        ],
      );
    });
  }

  // 感谢回复 request
  void onThankReply() async {
    var res = await DioRequestWeb.thankReply(reply.replyId, widget.topicId);
    if (res) {
      setState(() {
        reply.favoritesStatus = true;
        reply.favorites += 1;
      });
    }
    // else {
    //   SmartDialog.showToast('操作失败');
    // }
  }

  Future<void> takePicture() async {
    SmartDialog.showLoading(msg: '保存中');
    RenderRepaintBoundary boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image =
        await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name:
            "reply${reply.userName}_vvex${DateTime.now().toString().split('-').join()}");
    SmartDialog.dismiss();
    if (result != null) {
      if (result['isSuccess']) {
        SmartDialog.showToast('已保存到相册');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 450),
      child: SizedBox(
        height: ignoreStatus ? 0 : null,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: RepaintBoundary(
            key: repaintKey,
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: reply.isChoose ? Theme.of(context).colorScheme.onInverseSurface : null,
              child: InkWell(
                onTap: replyComment,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: content(context),
                ),
              ),
            ),
          ),
          // ),
        ),
      ),
    );
  }

  Widget lfAvtar() {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          reply.isChoose = !reply.isChoose;
        });
      },
      onTap: () => Get.toNamed('/member/${reply.userName}', parameters: {
        'memberAvatar': reply.avatar,
        'heroTag': reply.userName + heroTag,
      }),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18))),
            child: Stack(
              children: [
                Hero(
                  tag: reply.userName + heroTag,
                  child: CAvatar(
                    url: reply.avatar,
                    size: 34,
                  ),
                ),
                // if (reply.isChoose)
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedScale(
                    scale: reply.isChoose ? 1 : 0,
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 300),
                    child: Container(

                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.8),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      child: Icon(Icons.done,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // IconButton(onPressed: () => {}, icon: const Icon(Icons.celebration))
        ],
      ),
    );
  }

  Widget content(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 头像、昵称
        Row(
          // 两端对齐
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                lfAvtar(),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.userName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(width: 4),
                        if (reply.isOwner) ...[
                          Icon(
                            Icons.person,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Row(
                      children: [
                        if (reply.lastReplyTime.isNotEmpty) ...[
                          Text(
                            reply.lastReplyTime,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 2),
                        ],
                        if (reply.platform == 'Android') ...[
                          const Icon(
                            Icons.android,
                            size: 14,
                          ),
                        ],
                        if (reply.platform == 'iPhone') ...[
                          const Icon(Icons.apple, size: 16),
                        ]
                      ],
                    )
                  ],
                )
              ],
            ),
            IconButton(
              padding: const EdgeInsets.all(2.0),
              icon: const Icon(Icons.more_horiz_outlined, size: 18.0),
              onPressed: showBottomSheet,
            ),
            // Text(
            //   '#${reply.floorNumber}',
            //   style: Theme.of(context).textTheme.titleSmall,
            // )
          ],
        ),
        // title
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5, left: 45, right: 0),
          child: HtmlRender(
            htmlContent: reply.contentRendered,
            imgList: reply.imgList,
            fs: GStorage().getReplyFs()
          ),
        ),
        // Divider(indent: 0, endIndent: 10, height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15),),
        bottonAction()
      ],
    );
  }

  // 感谢、回复、复制
  Widget bottonAction() {
    var color = Theme.of(context).colorScheme.onBackground.withOpacity(0.8);
    var textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onBackground,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const SizedBox(width: 32),
            if (reply.replyMemberList.isNotEmpty &&
                widget.queryReplyList != null &&
                reply.floorNumber != 1)
              TextButton(
                onPressed: () => widget.queryReplyList(
                    reply.replyMemberList, reply.floorNumber, [reply]),
                child: Text(
                  '查看回复',
                  style: textStyle,
                ),
              ),
            if (reply.userName != GStorage().getUserInfo()['userName'])
              TextButton(
                onPressed: thanksDialog,
                child: Row(children: [
                  // 感谢状态
                  if (reply.favoritesStatus) ...[
                    Icon(Icons.favorite,
                        size: 17, color: Theme.of(context).colorScheme.primary),
                  ] else ...[
                    Icon(Icons.favorite_border, size: 17, color: color),
                  ],
                  const SizedBox(width: 2),
                  reply.favorites > 0
                      ? reply.favoritesStatus
                          ? Text(reply.favorites.toString(),
                              style: textStyle.copyWith(
                                  color: Theme.of(context).colorScheme.primary))
                          : Text(reply.favorites.toString(), style: textStyle)
                      : Text('感谢', style: textStyle),
                ]),
              ),
            // TextButton(
            //   onPressed: replyComment,
            //   child: Row(children: [
            //     Icon(Icons.reply, size: 20, color: color.withOpacity(0.8)),
            //     const SizedBox(width: 2),
            //     Text('回复', style: textStyle),
            //   ]),
            // ),
          ],
        ),
        Row(
          children: [
            Text('${reply.floorNumber}楼',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 14)
          ],
        )
      ],
    );
  }

  void showBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          //重要
          itemCount: sheetMenu.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              onTap: () {
                Navigator.pop(context);
                menuAction(sheetMenu[index]['id']);
              },
              minLeadingWidth: 0,
              iconColor: Theme.of(context).colorScheme.onSurface,
              leading: sheetMenu[index]['leading'],
              title: Text(
                sheetMenu[index]['title'],
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          },
        );
      },
    );
  }

  void showCopySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Scaffold(
          body: Center(
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: MediaQuery.of(context).padding.bottom,
                  left: 20,
                  right: 20),
              child: SelectionArea(
                  child: HtmlRender(htmlContent: widget.reply.contentRendered)),
            ),
          ),
        );
      },
    );
  }

  void thanksDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确认向该用户表示感谢吗？，将花费10个铜板💰'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('手滑了'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Ok');
              onThankReply();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
