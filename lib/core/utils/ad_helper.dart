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
    // 테스트 보상형 광고 ID
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  // ─── Unity Ads ───────────────────────────────────────────────────────────

  /// Unity Ads Game ID
  /// Unity 대시보드에서 발급받은 Game ID를 여기에 입력하세요.
  static String get unityGameId {
    if (Platform.isAndroid) {
      return '6064447';
    } else {
      return '6064446';
    }
  }

  /// Unity Ads 테스트 모드 여부 (디버그 빌드에서는 true)
  static bool get unityTestMode => !kReleaseMode;

  /// Unity Ads Placement ID — 보상형 광고
  /// Unity 대시보드의 Placement ID를 입력하세요.
  // TODO: 실제 Placement ID로 교체
  static String get unityRewardedPlacementId =>
      Platform.isAndroid ? 'Rewarded_Android' : 'Rewarded_iOS';

  /// Unity Ads Placement ID — 전면 광고
  // TODO: 실제 Placement ID로 교체
  static String get unityInterstitialPlacementId =>
      Platform.isAndroid ? 'Rewarded_Android' : 'Rewarded_iOS';
}
