import 'package:flutter/foundation.dart';
import 'dart:io';

class AdHelper {
  // 앱 ID
  // Android: ca-app-pub-8610826190373183~5503542141
  static String get appId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8610826190373183~5503542141';
      } else if (Platform.isIOS) {
        // [주의] 아직 iOS 정식 앱 ID가 없으므로 테스트 ID를 반환합니다.
        // 나중에 iOS 등록 후 아래 ID를 실제 ID로 교체해주세요.
        return 'ca-app-pub-3940256099942544~1458002511';
      }
    }
    // 테스트 앱 ID (AdMob 공식 테스트 ID)
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544~3347511713'
        : 'ca-app-pub-3940256099942544~1458002511';
  }

  // 보상형 광고 단위 ID (필요시 추가 발급 후 교체)
  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      // 현재는 제공해주신 ID가 하나이므로 이를 사용하거나,
      // 보상형 광고 전용 ID를 발급받으시면 아래 ID를 수정해주세요.
      return 'ca-app-pub-8610826190373183/3805214029';
    }
    // 테스트 보상형 광고 ID
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }
}
