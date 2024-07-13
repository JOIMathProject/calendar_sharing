import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;

class CreateContents extends StatefulWidget {
  @override
  _CreateContentsState createState() => _CreateContentsState();
}

class _CreateContentsState extends State<CreateContents> {
  @override
  String title = '';
  List<String> peoples = [];
  String people_field = '';
  TextStyle bigFont = TextStyle(fontSize: 20);
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('グループの作成'),
          actions: [
            IconButton(
              icon: Icon(Icons.arrow_back_outlined),
              onPressed: () {
              },
            ),],
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'グループ名',
                    ),
                    onChanged: (String value) {
                      setState(() {
                        title = value;
                      });
                    },
                    style: TextStyle(fontSize: 25),
                  ),
                ],
              ),
              SizedBox(height: 20),
              //人々の名前+削除ボタン
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //人の追加テキスト+追加ボタン
                  Text("追加済みアドレス", style: bigFont),
                  SizedBox(height: 10),
                  Column(
                    children: [
                      if (peoples.isEmpty)
                        Text('追加されているユーザーはいません')
                      else
                      for (var people in peoples)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(people, style: TextStyle(fontSize: 15)),
                            ElevatedButton(
                              onPressed: () {
                                //確認ウィンドウ
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('削除確認'),
                                      content: Text('本当に'+people+'を削除しますか？'),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          child: Text('削除'),
                                          onPressed: () {
                                            setState(() {
                                              peoples.remove(people);
                                            });
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ElevatedButton(
                                          child: Text('キャンセル'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(// ボタンのサイズ
                                shape: const CircleBorder(),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Icon(Icons.delete, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('人を追加'),
                            content: TextField(
                              decoration: InputDecoration(
                                hintText: 'example@gmail.com',
                              ),
                              onChanged: (String value) {
                                setState(() {
                                  people_field = value;
                                });
                              },
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                child: Text('追加'),
                                onPressed: () {
                                  setState(() {
                                    if (people_field != '') peoples.add(people_field);
                                  });
                                  people_field = '';
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Icon(Icons.add, size: 20),
                  ),
                  SizedBox(height: 30),
                  //作成ボタン
                  ElevatedButton(
                    onPressed: () {
                      //print('作成');
                    },
                    child: Text('作成'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, 30),
                    )
                  )
                ],
              )
            ],
          ),
        ));
  }
}
