import 'package:flutter/material.dart';
import 'package:flutter_v2ex/components/home/list_item.dart';
import 'package:flutter_v2ex/service/read.dart';
import 'package:sticky_headers/sticky_headers.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List historyList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHistoryTopic();
  }


  Future getHistoryTopic() async{
    var res = await Read().query();
    if(res.isNotEmpty){
      setState(() {
        historyList = res.reversed.toList();
      });
    }else{
      historyList = [];
    }
  }

  void clearHis() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("提示"),
        content: const Text('确定删除全部浏览记录吗？'),
        actions: [
          TextButton(onPressed: () =>Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () async{
            await Read().clear();
            setState(() {
              historyList = [];
            });
            if(context.mounted){
              Navigator.pop(context);
            }
          }, child: const Text('确定')),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近浏览'),
        actions: [
          IconButton(
              onPressed: historyList.isNotEmpty ? clearHis : null,
              tooltip: '清除浏览记录',
              icon: const Icon(Icons.clear_all_rounded),),
          const SizedBox(width: 12),
        ],
      ),
      body: historyList.isEmpty ? noData() : ListView.builder(
          itemCount: historyList.length,
          itemBuilder: (context, index) {
        return StickyHeaderBuilder(
          builder: (BuildContext context, double stuckAmount) {
            stuckAmount = 0.4 - stuckAmount.clamp(0.0, 1.0);
            return Container(
              height: 60.0,
              color: Theme.of(context).colorScheme.background,
              // color: Color.lerp(Theme.of(context).colorScheme.background, Theme.of(context).colorScheme.onInverseSurface, stuckAmount),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text(
                  historyList[index]['date'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                  Text(
                    '${historyList[index]['topicList'].length} 贴',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            );
          },
          content: Container(
            padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
            child: Column(
                children: [
                  for(var i in historyList[index]['topicList'])
                    ListItem(topic: i['content']),
                ]
            ),
          )
          ,
        );
      })
    );
  }

  Widget noData() {
    return const Center(
      child: Text('没有数据'),
    );
  }
}
