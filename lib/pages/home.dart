import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:logger/logger.dart';
import 'package:plat/audio_level_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  RtcEngine engine = createAgoraRtcEngine();
  Uint8List audioBuffer = Uint8List(0);
  SpeechToText stt = SpeechToText();
  DocumentReference docref =
      FirebaseFirestore.instance.collection('words').doc('eminem');
  String userId = const Uuid().v4().hashCode.abs().toString();
  String transcription = "";
  String myWords = "";

  bool isListening = false; // リスニング状態を追跡
  bool isSpeechToTextInitialized = false; // SpeechToTextの初期化状態を追跡

  @override
  void initState() {
    super.initState();
    init(); // 初期化を呼び出す
  }

  @override
  Future<void> dispose() async {
    stt.stop(); // 終了時に録音を停止
    await engine.leaveChannel(); // チャンネルを離脱
    await engine.release(); // リソースを解放
    super.dispose();
  }

  Future<void> init() async {
    // マイクのパーミッション確認
    await checkMicrophonePermission();

    // SpeechToTextの初期化
    bool available = await stt.initialize();
    setState(() {
      isSpeechToTextInitialized = available;
    });

    if (available) {
      Logger().i("Speech to Text initialized successfully");
      await startListen(); // 最初のリスニング開始
      //await initEngine(); // Agoraエンジンの初期化
      await startVolumeMonitoring(); // 音量監視開始

      docref.snapshots().listen((data) {
        Map<String, dynamic> wordsTable = (data.data() as Map<String, dynamic>);
        if (wordsTable.isNotEmpty) {
          wordsTable.removeWhere((key, value) => key == userId);
          if (wordsTable.isNotEmpty) {
            transcription = wordsTable.entries.first.value;
          }
        }
      });
    } else {
      Logger().e("Speech to Text initialization failed");
    }
  }

  Future<void> checkMicrophonePermission() async {
    if (await Permission.microphone.request().isGranted) {
      Logger().i("Microphone permission granted");
    } else {
      Logger().e("Microphone permission denied");
    }
  }

  Future<void> initEngine() async {
    await engine.initialize(const RtcEngineContext(
        appId: "8570eb80e45f4339b4c4eaffa04dab80",
        channelProfile: ChannelProfileType.channelProfileCommunication));
    await engine.joinChannel(
      token: "7591ed7446614bbc85bf56d6e8ae9ced",
      channelId: "eminem",
      options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster),
      uid: int.parse(userId),
    );
  }

  Future<void> startVolumeMonitoring() async {
    // 音量レベルの監視を開始
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      double volumeLevel = await AudioLevelService().getVolumeLevel();
      Logger().i("Volume level: $volumeLevel, Listening: $isListening");

      // 音量が正常な範囲で、リスニング中でない場合にのみ再開
      if (volumeLevel > 100 && !isListening) {
        await startListen(); // リスニングを再開
        Logger().i("Recording restarted due to volume.");
      }
    });
  }

  Future<void> startListen() async {
    setState(() {
      isListening = true;
    });

    try {
      // 録音と文字起こしを開始
      await stt.listen(
        onResult: (result) async {
          Logger().i("Recognized words: ${result.recognizedWords}");
          String words = result.recognizedWords.isNotEmpty
              ? result.recognizedWords
              : myWords;
          setState(() {
            myWords = words;
          });
          await docref.set({userId: words});
        },
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 10),
        listenOptions: SpeechListenOptions(cancelOnError: false),
      );
      Logger().i("end listenning");
    } catch (e) {
      Logger().e("Error starting listening: $e");
      setState(() {
        isListening = false;
      });
      return;
    }

    // リスニングが終了したら状態を更新
    setState(() {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Center(child: Text(transcription)),
                ),
              ),
              Expanded(
                child: Card(
                  child: Center(child: Text(myWords)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
