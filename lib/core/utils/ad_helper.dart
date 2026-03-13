import 'package:flutter/foundation.dart';
import 'dart:io';

class AdHelper {
  // ─── AdMob ───────────────────────────────────────────────────────────────

  // 앱 ID
  static String get appId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8610826190373183~5503542141';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8610826190373183~3901486756';
      }
    }
    // 테스트 앱 ID (AdMob 공식 테스트 ID)
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544~3347511713'
        : 'ca-app-pub-3940256099942544~1458002511';
  }

  // 보상형 광고 단위 ID (상점 광고 보기 버튼)
  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8610826190373183/4643694539';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8610826190373183/3509596324';
      }
    }
    // 테스트 보상형 광고 ID
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  // 보너스 보상형 광고 단위 ID (일기 완료 후 보너스 광고)
  static String get bonusRewardedAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8610826190373183/6459193294';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8610826190373183/1498986014';
      }
    }
    // 테스트 보상형 전면 광고 ID
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5354046379'
        : 'ca-app-pub-3940256099942544/6978759866';
  }


}
