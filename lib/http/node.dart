import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ex/models/version.dart';
import 'package:flutter_v2ex/service/read.dart';
import 'package:flutter_v2ex/utils/event_bus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:flutter_v2ex/http/init.dart';
import 'package:html/dom.dart'
as dom; // Contains DOM related classes for extracting data from elements
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:flutter_v2ex/package/xpath/xpath.dart';

import 'package:flutter_v2ex/models/web/item_tab_topic.dart'; // 首页tab主题列表
import 'package:flutter_v2ex/models/web/model_topic_detail.dart'; // 主题详情
import 'package:flutter_v2ex/models/web/item_topic_reply.dart'; // 主题回复
import 'package:flutter_v2ex/models/web/item_topic_subtle.dart'; // 主题附言
import 'package:flutter_v2ex/models/web/model_node_list.dart'; // 节点列表
import 'package:flutter_v2ex/models/web/model_topic_fav.dart'; // 收藏的主题
import 'package:flutter_v2ex/models/web/model_login_detail.dart'; // 用户登录字段
import 'package:flutter_v2ex/models/web/model_node_fav.dart';
import 'package:flutter_v2ex/models/web/model_member_reply.dart';
import 'package:flutter_v2ex/models/web/item_member_reply.dart';
import 'package:flutter_v2ex/models/web/model_member_topic.dart';
import 'package:flutter_v2ex/models/web/item_member_topic.dart';
import 'package:flutter_v2ex/models/web/item_member_social.dart';
import 'package:flutter_v2ex/models/web/model_member_profile.dart';
import 'package:flutter_v2ex/models/web/model_member_notice.dart';
import 'package:flutter_v2ex/models/web/item_member_notice.dart';
import 'package:flutter_v2ex/models/web/model_topic_follow.dart';

import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter_v2ex/utils/utils.dart';
import 'package:flutter_v2ex/utils/string.dart';
import 'package:flutter_v2ex/utils/storage.dart';

class NodeWebApi {

  // 获取节点下的主题
  static Future<NodeListModel> getTopicsByNodeId(String nodeId, int p) async {
    // print('------getTopicsByNodeKey---------');
    NodeListModel detailModel = NodeListModel();
    List<TabTopicItem> topics = [];
    Response response;
    // 请求PC端页面 lastReplyTime totalPage
    // Request().dio.options.headers = {};
    response = await Request().get(
      '/go/$nodeId',
      data: {'p': p},
      extra: {'ua': 'pc'},
    );
    var document = parse(response.data);
    var mainBox = document.body!.children[1].querySelector('#Main');
    var mainHeader = document.querySelector('div.box.box-title.node-header');
    detailModel.nodeCover =
    mainHeader!.querySelector('img')!.attributes['src']!;
    // 节点名称
    detailModel.nodeName =
    mainHeader.querySelector('div.node-breadcrumb')!.text.split('›')[1];
    // 主题总数
    detailModel.topicCount = mainHeader.querySelector('strong')!.text;
    // 节点描述
    if (mainHeader.querySelector('div.intro') != null) {
      detailModel.nodeIntro = mainHeader.querySelector('div.intro')!.text;
    }
    // 节点收藏状态
    if (mainHeader.querySelector('div.cell_ops') != null) {
      detailModel.isFavorite =
          mainHeader.querySelector('div.cell_ops')!.text.contains('取消');
      // 数字
      detailModel.nodeId = mainHeader
          .querySelector('div.cell_ops > div >a')!
          .attributes['href']!
          .split('=')[0]
          .replaceAll(RegExp(r'\D'), '');
    }
    if (mainBox!.querySelector(
        'div.box:not(.box-title)>div.cell:not(.tab-alt-container):not(.item)') !=
        null) {
      var totalpageNode = mainBox.querySelector(
          'div.box:not(.box-title)>div.cell:not(.tab-alt-container)');
      if (totalpageNode!.querySelectorAll('a.page_normal').isNotEmpty) {
        detailModel.totalPage = int.parse(
            totalpageNode.querySelectorAll('a.page_normal').last.text);
      }
    }

    if (document.querySelector('#TopicsNode') != null) {
      // 主题
      var topicEle =
      document.querySelector('#TopicsNode')!.querySelectorAll('div.cell');
      for (var aNode in topicEle) {
        var item = TabTopicItem();

        //  头像 昵称
        if (aNode.querySelector('td > a > img') != null) {
          item.avatar = aNode.querySelector('td > a > img')!.attributes['src']!;
          item.memberId =
          aNode.querySelector('td > a > img')!.attributes['alt']!;
        }

        if (aNode.querySelector('tr > td:nth-child(5)') != null) {
          item.topicTitle = aNode
              .querySelector('td:nth-child(5) > span.item_title')!
              .text
              .replaceAll('&quot;', '"')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');
          // var topicSub = aNode
          //     .querySelector('td:nth-child(5) > span.small')!
          //     .text
          //     .replaceAll('&nbsp;', "");
          // item.memberId = topicSub.split('•')[0].trim();
          // item.clickCount =
          //     topicSub.split('•')[2].trim().replaceAll(RegExp(r'[^0-9]'), '');
        }
        if (aNode.querySelector('tr > td:nth-child(5) > span > a') != null) {
          String? topicUrl = aNode
              .querySelector('tr > td:nth-child(5) > span > a')!
              .attributes['href']; // 得到是 /t/522540#reply17
          item.topicId = topicUrl!.replaceAll("/t/", "").split("#")[0];
          item.replyCount = int.parse(topicUrl
              .replaceAll("/t/", "")
              .split("#")[1]
              .replaceAll(RegExp(r'\D'), ''));
        }
        if (aNode.querySelector('tr') != null) {
          var topicTd = aNode.querySelector('tr')!.children[2];
          item.lastReplyTime = topicTd
              .querySelector('span.topic_info > span')!
              .text
              .replaceAll("/t/", "");
        }
        // item.nodeName = aNode.xpath("/table/tr/td[3]/span[1]/a/text()")![0].name!;
        topics.add(item);
      }
    }
    try{
      Read().mark(topics);
    }catch(err){
      print(err);
    }
    detailModel.topicList = topics;

    var noticeNode =
    document.body!.querySelector('#Rightbar>div.box>div.cell.flex-one-row');
    if (noticeNode != null) {
      // 未读消息
      var unRead =
      noticeNode.querySelector('a')!.text.replaceAll(RegExp(r'\D'), '');
      if (int.parse(unRead) > 0) {
        eventBus.emit('unRead', int.parse(unRead));
      }
    }

    return detailModel;
  }

  // 收藏节点
  static Future onFavNode(String nodeId, bool isFavorite) async {
    SmartDialog.showLoading(msg: isFavorite ? '取消收藏ing' : '收藏中ing');
    int once = GStorage().getOnce();
    Response response;
    var reqUrl =
    isFavorite ? '/unfavorite/node/$nodeId' : '/favorite/node/$nodeId';
    response = await Request().get(
      reqUrl,
      data: {'once': once},
      extra: {'ua': 'pc'},
    );
    SmartDialog.dismiss();
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

}