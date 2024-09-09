import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AudioLevelService {
  static const platform = MethodChannel('com.example.audiorecord/volume');

  Future<double> getVolumeLevel() async {
    try {
      return await platform.invokeMethod('getVolumeLevel');
    } on PlatformException catch (e) {
      Logger().i("Failed to get volume level: '${e.message}'.");
      return 0;
    }
  }
}
