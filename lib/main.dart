import 'dart:ffi';

import 'package:docking/docking.dart';
import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:flutter/material.dart';
import 'dart:async';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DockingLayout _layout;
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isWebviewSuspended = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  DockingItem _build(int value, {bool closable = true, bool? maximizable}) {
    DockingItem item = DockingItem(
        name: value.toString(),
        closable: closable,
        maximizable: maximizable,
        widget: Container(child: Center(child: Text('Child $value'))));

    return item;
  }

  Future<void> initPlatformState() async {
    // Optionally initialize the webview environment using
    // a custom user data directory and/or custom chromium command line flags
    //await WebviewController.initializeEnvironment(
    //    additionalArguments: '--show-fps-counter');

    await _controller.initialize();
    _controller.url.listen((url) {
      _textController.text = url;
    });

    // await _controller.setBackgroundColor(Colors.transparent);
    await _controller.loadUrl('https://www.tradingview.com/chart/');

    // if (!mounted) return;

    setState(() {});
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 0,
              child: TextField(
                decoration: InputDecoration(
                    hintText: 'URL',
                    contentPadding: EdgeInsets.all(10.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        _controller.reload();
                      },
                    )),
                textAlignVertical: TextAlignVertical.center,
                controller: _textController,
                onSubmitted: (val) {
                  _controller.loadUrl(val);
                },
              ),
            ),
            Expanded(
                child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      children: [
                        Webview(
                          width: 1024,
                          height: 768,
                          _controller,
                          permissionRequested: _onPermissionRequested,
                        ),
                        StreamBuilder<LoadingState>(
                            stream: _controller.loadingState,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data == LoadingState.loading) {
                                return LinearProgressIndicator();
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int v = 1;
    _layout = DockingLayout(
        root: DockingRow([
      DockingItem(widget: compositeView()),
      DockingColumn([
        DockingRow(
            [_build(v++, maximizable: false), _build(v++, closable: false)]),
        DockingTabs([_build(v++), _build(v++), _build(v++)]),
        _build(v++)
      ])
    ]));

    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: Center(
          widthFactor: 2,
          child: Container(
              child: Docking(layout: _layout), padding: EdgeInsets.all(16)),
        ),
      ),
    );
    // return Scaffold(
    //     body: TabbedViewTheme(
    //         data: TabbedViewThemeData.classic(),
    //         child: Container(
    //             child: Docking(layout: _layout), padding: EdgeInsets.all(16))));
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }
}

class DockingExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Docking example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DockingExamplePage(),
    );
  }
}

class DockingExamplePage extends StatefulWidget {
  @override
  _DockingExamplePageState createState() => _DockingExamplePageState();
}

class _DockingExamplePageState extends State<DockingExamplePage> {
  late DockingLayout _layout;

  @override
  void initState() {
    super.initState();

    int v = 1;
    _layout = DockingLayout(
        root: DockingRow([
      _build(v++),
      DockingColumn([
        DockingRow(
            [_build(v++, maximizable: false), _build(v++, closable: false)]),
        DockingTabs([_build(v++), _build(v++), _build(v++)]),
        _build(v++)
      ])
    ]));
  }

  DockingItem _build(int value, {bool closable = true, bool? maximizable}) {
    DockingItem item = DockingItem(
        name: value.toString(),
        closable: closable,
        maximizable: maximizable,
        widget: Container(child: Center(child: Text('Child $value'))));

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: TabbedViewTheme(
            data: TabbedViewThemeData.classic(),
            child: Container(
                child: Docking(layout: _layout), padding: EdgeInsets.all(16))));
  }
}
