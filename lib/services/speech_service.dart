import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// 语音识别服务
///
/// 封装speech_to_text包，提供简单的语音转文字接口
class SpeechService {
  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._();

  SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// 初始化语音识别
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 请求麦克风权限
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (kDebugMode) {
          debugPrint('Microphone permission denied');
        }
        return false;
      }

      // 初始化语音识别
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            debugPrint('Speech recognition error: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          if (kDebugMode) {
            debugPrint('Speech recognition status: $status');
          }
        },
      );

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize speech recognition: $e');
      }
      return false;
    }
  }

  /// 开始监听
  ///
  /// [onResult] 识别结果回调（实时返回）
  /// [onFinalResult] 最终结果回调（松手后返回）
  /// [locale] 语言代码，默认简体中文 'zh_CN'
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String text)? onFinalResult,
    String locale = 'zh_CN',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      if (kDebugMode) {
        debugPrint('Already listening');
      }
      return false;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;

          // 实时结果回调
          if (text.isNotEmpty) {
            onResult(text);
          }

          // 最终结果回调
          if (result.finalResult && onFinalResult != null) {
            onFinalResult(text);
          }
        },
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );

      _isListening = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to start listening: $e');
      }
      return false;
    }
  }

  /// 停止监听
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to stop listening: $e');
      }
    }
  }

  /// 取消监听（不触发最终结果）
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to cancel listening: $e');
      }
    }
  }

  /// 获取可用的语言列表
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    return _speech.locales();
  }

  /// 检查是否正在监听
  bool get isListening => _isListening;

  /// 检查是否可用
  bool get isAvailable => _speech.isAvailable;

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 释放资源
  void dispose() {
    _speech.stop();
    _isListening = false;
  }
}
