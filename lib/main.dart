import 'package:easy_meal_mobile/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  var cameraStatus = await Permission.camera.request();
  if (cameraStatus.isGranted) {
    String? token = await FirebaseApi.init();
    runApp(MyApp(fcmToken: token));
  } else {
    print("Камера не доступна. Пожалуйста, предоставьте разрешение.");
  }
}

class MyApp extends StatefulWidget {
  final String? fcmToken;

  const MyApp({Key? key, this.fcmToken}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: ClipRRect(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('https://dev.easymeal.kz/login'),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStop: (controller, url) async {
                  if (widget.fcmToken != null) {
                    await webViewController.evaluateJavascript(
                      source: 'window.receiveFirebaseToken(\'${widget.fcmToken}\');',
                    );
                  }
                },
                androidOnPermissionRequest: (controller, origin, resources) async {
                  // Обработка запроса разрешений
                  if (resources.contains('android.webkit.resource.VIDEO_CAPTURE')) {
                    var cameraStatus = await Permission.camera.status;
                    if (cameraStatus.isGranted) {
                      return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT,
                      );
                    } else {
                      return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.DENY,
                      );
                    }
                  }
                  return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.DENY,
                  );
                },
                onConsoleMessage: (controller, message) {
                  print("Console Message: ${message.message}");
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
