import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plat/firebase_options.dart';
import 'package:plat/pages/home.dart';

Future<void> requestWebRTCPermissions() async {
  // カメラとマイクのパーミッションをリクエスト
  final cameraPermission = await Permission.camera.request();
  final microphonePermission = await Permission.microphone.request();

  // パーミッションの状態を確認
  if (cameraPermission.isGranted && microphonePermission.isGranted) {
    Logger().i("カメラとマイクのパーミッションが許可されました");
  } else {
    Logger().e("カメラまたはマイクのパーミッションが拒否されました");
    // パーミッションが拒否された場合の処理を追加
    // 例えば、ユーザーに設定画面でのパーミッション許可を促す
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primaryColor: const Color.fromRGBO(134, 193, 102, 1)),
        home: const HomePage());
  }
}
