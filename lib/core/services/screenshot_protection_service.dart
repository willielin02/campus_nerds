import 'dart:async';
import 'dart:io';

import 'package:no_screenshot/no_screenshot.dart';

/// 截圖保護服務（僅 iOS）
///
/// - iOS：no_screenshot 內容隱藏 + screenshotStream 偵測截圖 → 自訂 Dialog
/// - Android：不做處理（API 限制，無法可靠偵測截圖）
class ScreenshotProtectionService {
  ScreenshotProtectionService._();
  static final instance = ScreenshotProtectionService._();

  final _noScreenshot = NoScreenshot.instance;

  /// 截圖偵測事件串流（僅 iOS）
  final _controller = StreamController<void>.broadcast();
  Stream<void> get onScreenshotDetected => _controller.stream;

  StreamSubscription? _iosSubscription;
  bool _isListening = false;

  /// 啟用截圖保護（僅 iOS）
  Future<void> enable() async {
    if (Platform.isIOS) {
      await _noScreenshot.screenshotOff();
    }
  }

  /// 停用截圖保護（僅 iOS）
  Future<void> disable() async {
    if (Platform.isIOS) {
      await _noScreenshot.screenshotOn();
    }
  }

  /// 開始監聽截圖事件（僅 iOS）
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    if (Platform.isIOS) {
      _noScreenshot.startScreenshotListening();
      _iosSubscription =
          _noScreenshot.screenshotStream.listen((snapshot) {
        if (snapshot.wasScreenshotTaken) {
          _controller.add(null);
        }
      });
    }
  }

  /// 停止監聽截圖事件
  void stopListening() {
    if (!_isListening) return;
    _isListening = false;

    if (Platform.isIOS) {
      _noScreenshot.stopScreenshotListening();
    }
    _iosSubscription?.cancel();
    _iosSubscription = null;
  }
}
