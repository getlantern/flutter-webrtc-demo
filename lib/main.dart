import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/call_sample/call_sample.dart';
import 'src/call_sample/data_channel_sample.dart';
import 'src/route_item.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MyAppState extends State<MyApp> {
  var mc = MethodChannel('mc');
  var mc2 = MethodChannel('mc2');

  List<RouteItem> items;
  String _selfMessengerId = '';
  String _peerMessengerId = '';
  SharedPreferences _prefs;

  bool _datachannel = false;

  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
    mc.invokeMethod("getMessengerId").then((value) => setState(() {
          _selfMessengerId = value as String;
        }));
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter-WebRTC example'),
        ),
        body: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(0.0),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  return _buildRow(context, items[i]);
                }),
            Text('Your ID'),
            InkWell(
              onTap: () {
                Clipboard.setData(new ClipboardData(text: _selfMessengerId));
              },
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(_selfMessengerId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _peerMessengerId =
          _prefs.getString('peerMessengerId') ?? 'demo.cloudwebrtc.com';
    });
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          _prefs.setString('peerMessengerId', _peerMessengerId);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _datachannel
                      ? DataChannelSample(
                          mc: mc,
                          mc2: mc2,
                          selfMessengerId: _selfMessengerId,
                          peerMessengerId: _peerMessengerId)
                      : CallSample(
                          mc: mc,
                          mc2: mc2,
                          selfMessengerId: _selfMessengerId,
                          peerMessengerId: _peerMessengerId)));
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text('Enter other party\'s messenger ID:'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _peerMessengerId = text;
                });
              },
              decoration: InputDecoration(
                hintText: _peerMessengerId,
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              FlatButton(
                  child: const Text('CONNECT'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.connect);
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'P2P Call Sample',
          subtitle: 'P2P Call Sample.',
          push: (BuildContext context) {
            _datachannel = false;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Data Channel Sample',
          subtitle: 'P2P Data Channel.',
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
    ];
  }
}
