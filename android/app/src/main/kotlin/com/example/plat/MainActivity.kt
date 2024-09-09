package com.example.plat

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.audiorecord/volume"
    private var audioRecord: AudioRecord? = null
    private var bufferSize: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // AudioRecordの初期化
        bufferSize = AudioRecord.getMinBufferSize(
            16000,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            16000,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getVolumeLevel") {
                val volumeLevel = getVolumeLevel()
                result.success(volumeLevel)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getVolumeLevel(): Float {
        val buffer = ShortArray(bufferSize)

        audioRecord?.startRecording()
        audioRecord?.read(buffer, 0, buffer.size)
        audioRecord?.stop()

        // 音量レベルの計算
        val sum = buffer.map { it * it.toLong() }.sum()

        return if (buffer.isNotEmpty()) {
            val rms = Math.sqrt(sum / buffer.size.toDouble())
            rms.toFloat()
        } else {
            0f
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        audioRecord?.release() // リソース解放
    }
}
