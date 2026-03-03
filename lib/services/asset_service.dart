import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/constants/room_assets.dart';
import '../core/constants/character_assets.dart';

class AssetService {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('AssetService: FirebaseFirestore 인스턴스 획득 실패');
      rethrow;
    }
  }

  FirebaseStorage get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      debugPrint('AssetService: FirebaseStorage 인스턴스 획득 실패');
      rethrow;
    }
  }

  Future<void> fetchDynamicAssets() async {
    try {
      final snapshot = await _db.collection('assets').get();

      final docs = snapshot.docs;
      int addedCount = 0;
      int updatedCount = 0;

      for (var doc in docs) {
        final data = doc.data();
        final String category = data['category'] ?? 'prop';
        final String? firestoreImageUrl = data['imageUrl'];

        // createdAt 타임스탬프를 DateTime으로 변환
        DateTime? releasedAt;
        if (data['createdAt'] != null) {
          try {
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              releasedAt = ts.toDate();
            }
          } catch (_) {}
        }

        final newAsset = RoomAsset(
          id: doc.id,
          name: data['name'] ?? '',
          nameKo: data['nameKo'],
          nameEn: data['nameEn'],
          price: (data['price'] ?? 0).toInt(),
          icon: Icons.star,
          imagePath: firestoreImageUrl,
          sizeMultiplier: (data['sizeMultiplier'] ?? 1.0).toDouble(),
          aspectRatio: (data['aspectRatio'] ?? 1.0).toDouble(),
          isWallMounted: data['isWallMounted'] ?? false,
          noShadow: data['noShadow'] ?? false,
          shadowDyCorrection: (data['shadowDyCorrection'] ?? 0.0).toDouble(),
          isLight: data['isLight'] ?? false,
          lightIntensity: (data['lightIntensity'] ?? 1.0).toDouble(),
          isThinWindow: data['isThinWindow'] ?? false,
          isArchWindow: data['isArchWindow'] ?? false,
          windowBgScale: (data['windowBgScale'] ?? 1.0).toDouble(),
          releasedAt: releasedAt,
          category: category,
          charWidthPct:
              (data['charWidthPct'] ?? (data['charWidth']?.toDouble()))
                  ?.toDouble(),
          charTopPctAwake:
              (data['charTopPctAwake'] ?? (data['charTopAwake']?.toDouble()))
                  ?.toDouble(),
          charTopPctSleep:
              (data['charTopPctSleep'] ?? (data['charTopSleep']?.toDouble()))
                  ?.toDouble(),
          charBottomPct: (data['charBottomPct']?.toDouble()),
          charScaleAwake: (data['charScaleAwake']?.toDouble()),
          charScaleSleep: (data['charScaleSleep']?.toDouble()),
        );

        _upsertAsset(
            category, newAsset, () => addedCount++, () => updatedCount++);
      }
      debugPrint(
          '동적 에셋 로드 완료: ${docs.length}개 처리됨 (신규: $addedCount, 업데이트: $updatedCount)');
      debugPrint(
          '현재 에셋 수 - props: ${RoomAssets.props.length}, wallpapers: ${RoomAssets.wallpapers.length}, backgrounds: ${RoomAssets.backgrounds.length}, floors: ${RoomAssets.floors.length}, emoticons: ${RoomAssets.emoticons.length}, windows: ${RoomAssets.windows.length}');
    } catch (e) {
      debugPrint('동적 에셋 로드 실패: $e');
    }
  }

  /// 카테고리별 리스트에 에셋을 추가하거나 업데이트합니다.
  /// 기존 아이템에 로컬 에셋 경로가 있으면 보존합니다.
  void _upsertAsset(String category, RoomAsset newAsset, VoidCallback onAdded,
      VoidCallback onUpdated) {
    final List<RoomAsset>? targetList;
    switch (category) {
      case 'prop':
        targetList = RoomAssets.props;
        break;
      case 'wallpaper':
        targetList = RoomAssets.wallpapers;
        break;
      case 'background':
        targetList = RoomAssets.backgrounds;
        break;
      case 'floor':
        targetList = RoomAssets.floors;
        break;
      case 'emoticon':
        targetList = RoomAssets.emoticons;
        break;
      case 'window':
        targetList = RoomAssets.windows;
        break;
      case 'character':
      case 'face':
      case 'body':
      case 'head':
      case 'clothes':
        targetList = CharacterAssets.items;
        break;
      default:
        targetList = null;
    }

    if (targetList == null) return;

    final index = targetList.indexWhere((p) => p.id == newAsset.id);
    if (index != -1) {
      final existingImagePath = targetList[index].imagePath;
      // 기존 아이템에 로컬 에셋 경로가 있으면 보존 (로컬 에셋이 더 안정적)
      final existingIsLocal = existingImagePath != null &&
          existingImagePath.isNotEmpty &&
          !existingImagePath.startsWith('http');

      targetList[index] = existingIsLocal
          ? newAsset.copyWithImagePath(existingImagePath)
          : newAsset;
      onUpdated();
    } else {
      targetList.add(newAsset);
      onAdded();
    }
  }

  // 기존 로컬 에셋들을 Firestore로 일괄 업로드하기 위한 마이그레이션 함수 (관리자용 1회성)
  Future<void> migrateLocalAssetsToFirestore() async {
    try {
      // 1. Firestore에서 이미 존재하는 에셋 정보 가져오기 (ID + imageUrl 포함)
      final existingSnapshot = await _db.collection('assets').get();
      // doc ID → imageUrl 맵
      final existingAssets = <String, String?>{
        for (var doc in existingSnapshot.docs)
          doc.id: doc.data()['imageUrl'] as String?,
      };
      debugPrint('Firestore 기등록 에셋 수: ${existingAssets.length}');

      final batch = _db.batch();
      // fetchDynamicAssets()로 인해 RoomAssets가 덮어써졌을 수 있으므로
      // 카테고리 원본 이름만 사용하여 처리
      final allAssetsMap = {
        'prop': RoomAssets.props,
        'wallpaper': RoomAssets.wallpapers,
        'background': RoomAssets.backgrounds,
        'floor': RoomAssets.floors,
        'emoticon': RoomAssets.emoticons,
        'window': RoomAssets.windows,
        'character': CharacterAssets.items,
      };

      int uploadCount = 0;

      for (var entry in allAssetsMap.entries) {
        final category = entry.key;
        final assetList = entry.value;

        for (var prop in assetList) {
          final existingImageUrl = existingAssets[prop.id];

          // 스킵 조건:
          // 1) 이미 Firestore에 유효한 원격 URL이 저장된 경우
          // 2) 로컬 목록에서도 이미 원격 URL인 경우 (fetchDynamicAssets로 덮어써진 경우)
          final hasValidRemoteUrl = existingImageUrl != null &&
              existingImageUrl.isNotEmpty &&
              existingImageUrl.startsWith('http');
          final isAlreadyRemote =
              prop.imagePath != null && prop.imagePath!.startsWith('http');

          if (hasValidRemoteUrl || isAlreadyRemote) {
            continue;
          }

          // 로컬 imagePath가 없으면 스킵
          if (prop.imagePath == null || prop.imagePath!.isEmpty) {
            continue;
          }

          debugPrint(
              '신규/재업로드 대상: ${prop.id} (Firestore imageUrl: $existingImageUrl)');

          String? downloadUrl;
          if (prop.imagePath != null && prop.imagePath!.isNotEmpty) {
            try {
              final byteData = await rootBundle.load(prop.imagePath!);
              final uint8List = byteData.buffer.asUint8List();

              final storageRef =
                  _storage.ref().child('assets/$category/${prop.id}.png');
              await storageRef.putData(
                  uint8List, SettableMetadata(contentType: 'image/png'));
              downloadUrl = await storageRef.getDownloadURL();
              debugPrint('${prop.id} 스토리지 업로드 성공');
              uploadCount++;
            } catch (e) {
              debugPrint('${prop.id} 스토리지 업로드 실패: $e');
              downloadUrl = prop.imagePath;
            }
          }

          final docRef = _db.collection('assets').doc(prop.id);
          batch.set(
              docRef,
              {
                'category': category,
                'name': prop.name,
                'price': prop.price,
                'imageUrl': downloadUrl ?? prop.imagePath,
                'sizeMultiplier': prop.sizeMultiplier,
                'aspectRatio': prop.aspectRatio,
                'isWallMounted': prop.isWallMounted,
                'noShadow': prop.noShadow,
                'shadowDyCorrection': prop.shadowDyCorrection,
                'isLight': prop.isLight,
                'lightIntensity': prop.lightIntensity,
                'isArchWindow': prop.isArchWindow,
                'windowBgScale': prop.windowBgScale,
              },
              SetOptions(merge: true));
        }
      }

      if (uploadCount > 0) {
        await batch.commit();
        debugPrint('총 $uploadCount개의 신규/재업로드 에셋 마이그레이션 완료!');
      } else {
        debugPrint('업로드할 신규 에셋이 없습니다. (모든 에셋이 이미 Firebase Storage에 존재함)');
      }
    } catch (e) {
      debugPrint('마이그레이션 오류: $e');
    }
  }

  Future<void> addNewAsset({
    required String id,
    required String name,
    String? nameKo,
    String? nameEn,
    required int price,
    required String category,
    required Uint8List imageBytes,
    double sizeMultiplier = 1.0,
    double aspectRatio = 1.0,
    bool isWallMounted = false,
    bool noShadow = false,
    double shadowDyCorrection = 0.0,
    bool isLight = false,
    double lightIntensity = 1.0,
    bool isThinWindow = false,
    bool isArchWindow = false,
    double windowBgScale = 1.0,
    double? charWidthPct,
    double? charTopPctAwake,
    double? charTopPctSleep,
    double? charBottomPct,
    double? charScaleAwake,
    double? charScaleSleep,
  }) async {
    try {
      // 이미지 화질 및 크기 유지한 채로 Storage 업로드
      final storageRef = _storage.ref().child('assets/$category/$id.png');
      await storageRef.putData(
          imageBytes, SettableMetadata(contentType: 'image/png'));
      final downloadUrl = await storageRef.getDownloadURL();

      // DB 텍스트 정보 저장
      final docRef = _db.collection('assets').doc(id);
      await docRef.set({
        'name': name,
        'nameKo': nameKo,
        'nameEn': nameEn,
        'category': category,
        'price': price,
        'imageUrl': downloadUrl,
        'sizeMultiplier': sizeMultiplier,
        'aspectRatio': aspectRatio,
        'isWallMounted': isWallMounted,
        'noShadow': noShadow,
        'shadowDyCorrection': shadowDyCorrection,
        'isLight': isLight,
        'lightIntensity': lightIntensity,
        'isThinWindow': isThinWindow,
        'isArchWindow': isArchWindow,
        'windowBgScale': windowBgScale,
        'charWidthPct': charWidthPct,
        'charTopPctAwake': charTopPctAwake,
        'charTopPctSleep': charTopPctSleep,
        'charBottomPct': charBottomPct,
        'charScaleAwake': charScaleAwake,
        'charScaleSleep': charScaleSleep,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 새로 고침하여 로컬 스토어에 라이브 반영
      await fetchDynamicAssets();
      debugPrint('신규 에셋 [$id] 업로드 및 라이브 반영 완료');
    } catch (e) {
      debugPrint('신규 에셋 업로드 실패: $e');
      rethrow;
    }
  }

  Future<void> updateAsset({
    required String id,
    required String name,
    String? nameKo,
    String? nameEn,
    required int price,
    required String category,
    Uint8List? imageBytes,
    required String existingImageUrl,
    double sizeMultiplier = 1.0,
    double aspectRatio = 1.0,
    bool isWallMounted = false,
    bool noShadow = false,
    double shadowDyCorrection = 0.0,
    bool isLight = false,
    double lightIntensity = 1.0,
    bool isThinWindow = false,
    bool isArchWindow = false,
    double windowBgScale = 1.0,
    double? charWidthPct,
    double? charTopPctAwake,
    double? charTopPctSleep,
    double? charBottomPct,
    double? charScaleAwake,
    double? charScaleSleep,
  }) async {
    try {
      String downloadUrl = existingImageUrl;
      if (imageBytes != null) {
        final storageRef = _storage.ref().child('assets/$category/$id.png');
        await storageRef.putData(
            imageBytes, SettableMetadata(contentType: 'image/png'));
        downloadUrl = await storageRef.getDownloadURL();
      }

      final docRef = _db.collection('assets').doc(id);
      await docRef.update({
        'name': name,
        'nameKo': nameKo,
        'nameEn': nameEn,
        'category': category,
        'price': price,
        'imageUrl': downloadUrl,
        'sizeMultiplier': sizeMultiplier,
        'aspectRatio': aspectRatio,
        'isWallMounted': isWallMounted,
        'noShadow': noShadow,
        'shadowDyCorrection': shadowDyCorrection,
        'isLight': isLight,
        'lightIntensity': lightIntensity,
        'isThinWindow': isThinWindow,
        'isArchWindow': isArchWindow,
        'windowBgScale': windowBgScale,
        'charWidthPct': charWidthPct,
        'charTopPctAwake': charTopPctAwake,
        'charTopPctSleep': charTopPctSleep,
        'charBottomPct': charBottomPct,
        'charScaleAwake': charScaleAwake,
        'charScaleSleep': charScaleSleep,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchDynamicAssets();
      debugPrint('에셋 [$id] 업데이트 및 반영 완료');
    } catch (e) {
      debugPrint('에셋 업데이트 실패: $e');
      rethrow;
    }
  }

  Future<void> deleteAsset(String id, String category) async {
    try {
      await _db.collection('assets').doc(id).delete();
      try {
        await _storage.ref().child('assets/$category/$id.png').delete();
      } catch (e) {
        debugPrint('스토리지 파일 삭제 실패 (무시됨): $e');
      }

      // 로컬 메모리에서도 삭제
      RoomAssets.props.removeWhere((p) => p.id == id);
      RoomAssets.wallpapers.removeWhere((p) => p.id == id);
      RoomAssets.backgrounds.removeWhere((p) => p.id == id);
      RoomAssets.floors.removeWhere((p) => p.id == id);
      RoomAssets.emoticons.removeWhere((p) => p.id == id);
      RoomAssets.windows.removeWhere((p) => p.id == id);
      CharacterAssets.items.removeWhere((p) => p.id == id);

      debugPrint('에셋 [$id] 삭제 완료');
    } catch (e) {
      debugPrint('에셋 삭제 실패: $e');
      rethrow;
    }
  }
}
