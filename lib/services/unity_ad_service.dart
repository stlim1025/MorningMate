import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/utils/ad_helper.dart';

/// Unity Ads 초기화 및 광고 로드/노출을 담당하는 서비스.
/// 사용 방법:
///   final service = UnityAdService();
///   await service.initialize();
///   service.loadRewarded();
///   service.showRewarded(onComplete: () { /* 보상 지급 */ });
class UnityAdService {
  bool _isInitialized = false;
  bool _isRewardedReady = false;
  bool _isInterstitialReady = false;

  bool get isInitialized => _isInitialized;
  bool get isRewardedReady => _isRewardedReady;
  bool get isInterstitialReady => _isInterstitialReady;

  /// Unity Ads SDK를 초기화합니다.
  Future<void> initialize() async {
    try {
      await UnityAds.init(
        gameId: AdHelper.unityGameId,
        testMode: AdHelper.unityTestMode,
        onComplete: () {
          _isInitialized = true;
          debugPrint('[UnityAds] Initialization complete. testMode=${AdHelper.unityTestMode}');
          // 초기화 완료 후 광고 미리 로드
          loadRewarded();
          loadInterstitial();
        },
        onFailed: (error, message) {
          debugPrint('[UnityAds] Initialization failed: $error $message');
        },
      );
    } catch (e) {
      debugPrint('[UnityAds] Exception during init: $e');
    }
  }

  /// 보상형 광고 로드
  void loadRewarded() {
    if (!_isInitialized) return;
    UnityAds.load(
      placementId: AdHelper.unityRewardedPlacementId,
      onComplete: (placementId) {
        _isRewardedReady = true;
        debugPrint('[UnityAds] Rewarded loaded: $placementId');
      },
      onFailed: (placementId, error, message) {
        _isRewardedReady = false;
        debugPrint('[UnityAds] Rewarded load failed: $placementId $error $message');
      },
    );
  }

  /// 전면 광고 로드
  void loadInterstitial() {
    if (!_isInitialized) return;
    UnityAds.load(
      placementId: AdHelper.unityInterstitialPlacementId,
      onComplete: (placementId) {
        _isInterstitialReady = true;
        debugPrint('[UnityAds] Interstitial loaded: $placementId');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialReady = false;
        debugPrint('[UnityAds] Interstitial load failed: $placementId $error $message');
      },
    );
  }

  /// 보상형 광고 노출.
  /// [onComplete] : 광고를 끝까지 시청했을 때 호출 (보상 지급).
  /// [onSkipped]  : 광고를 스킵했을 때 호출.
  void showRewarded({
    required VoidCallback onComplete,
    VoidCallback? onSkipped,
    VoidCallback? onFailed,
  }) {
    if (!_isRewardedReady) {
      debugPrint('[UnityAds] Rewarded not ready.');
      onFailed?.call();
      return;
    }

    _isRewardedReady = false; // 보여주는 동안 플래그 리셋

    UnityAds.showVideoAd(
      placementId: AdHelper.unityRewardedPlacementId,
      onStart: (id) => debugPrint('[UnityAds] Rewarded started: $id'),
      onClick: (id) => debugPrint('[UnityAds] Rewarded clicked: $id'),
      onSkipped: (id) {
        debugPrint('[UnityAds] Rewarded skipped: $id');
        loadRewarded(); // 다음 광고 미리 로드
        onSkipped?.call();
      },
      onComplete: (id) {
        debugPrint('[UnityAds] Rewarded completed: $id');
        loadRewarded(); // 다음 광고 미리 로드
        onComplete();
      },
      onFailed: (id, error, message) {
        debugPrint('[UnityAds] Rewarded show failed: $id $error $message');
        loadRewarded();
        onFailed?.call();
      },
    );
  }

  /// 전면 광고 노출.
  void showInterstitial({
    VoidCallback? onComplete,
    VoidCallback? onSkipped,
    VoidCallback? onFailed,
  }) {
    if (!_isInterstitialReady) {
      debugPrint('[UnityAds] Interstitial not ready.');
      onFailed?.call();
      return;
    }

    _isInterstitialReady = false;

    UnityAds.showVideoAd(
      placementId: AdHelper.unityInterstitialPlacementId,
      onStart: (id) => debugPrint('[UnityAds] Interstitial started: $id'),
      onClick: (id) => debugPrint('[UnityAds] Interstitial clicked: $id'),
      onSkipped: (id) {
        debugPrint('[UnityAds] Interstitial skipped: $id');
        loadInterstitial();
        onSkipped?.call();
      },
      onComplete: (id) {
        debugPrint('[UnityAds] Interstitial completed: $id');
        loadInterstitial();
        onComplete?.call();
      },
      onFailed: (id, error, message) {
        debugPrint('[UnityAds] Interstitial show failed: $id $error $message');
        loadInterstitial();
        onFailed?.call();
      },
    );
  }
}
