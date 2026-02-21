import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/constants/room_assets.dart';

class AssetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> fetchDynamicAssets() async {
    try {
      final snapshot = await _db.collection('assets').get();

      final docs = snapshot.docs;
      for (var doc in docs) {
        final data = doc.data();
        final String category = data['category'] ?? 'prop';

        final newAsset = RoomAsset(
          id: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toInt(),
          icon: Icons.star, // 기본 아이콘 설정
          imagePath: data['imageUrl'], // 원격 URL
          sizeMultiplier: (data['sizeMultiplier'] ?? 1.0).toDouble(),
          aspectRatio: (data['aspectRatio'] ?? 1.0).toDouble(),
          isWallMounted: data['isWallMounted'] ?? false,
          noShadow: data['noShadow'] ?? false,
          shadowDyCorrection: (data['shadowDyCorrection'] ?? 0.0).toDouble(),
          isLight: data['isLight'] ?? false,
          lightIntensity: (data['lightIntensity'] ?? 1.0).toDouble(),
          category: category,
        );

        if (category == 'prop') {
          final index = RoomAssets.props.indexWhere((p) => p.id == newAsset.id);
          if (index != -1) {
            RoomAssets.props[index] = newAsset;
          } else {
            RoomAssets.props.add(newAsset);
          }
        } else if (category == 'wallpaper') {
          final index =
              RoomAssets.wallpapers.indexWhere((p) => p.id == newAsset.id);
          if (index != -1)
            RoomAssets.wallpapers[index] = newAsset;
          else
            RoomAssets.wallpapers.add(newAsset);
        } else if (category == 'background') {
          final index =
              RoomAssets.backgrounds.indexWhere((p) => p.id == newAsset.id);
          if (index != -1)
            RoomAssets.backgrounds[index] = newAsset;
          else
            RoomAssets.backgrounds.add(newAsset);
        } else if (category == 'floor') {
          final index =
              RoomAssets.floors.indexWhere((p) => p.id == newAsset.id);
          if (index != -1)
            RoomAssets.floors[index] = newAsset;
          else
            RoomAssets.floors.add(newAsset);
        } else if (category == 'emoticon') {
          final index =
              RoomAssets.emoticons.indexWhere((p) => p.id == newAsset.id);
          if (index != -1)
            RoomAssets.emoticons[index] = newAsset;
          else
            RoomAssets.emoticons.add(newAsset);
        }
      }
      debugPrint('동적 에셋 로드 완료: ${docs.length}개 처리됨');
    } catch (e) {
      debugPrint('동적 에셋 로드 실패: $e');
    }
  }

  // 기존 로컬 에셋들을 Firestore로 일괄 업로드하기 위한 마이그레이션 함수 (관리자용 1회성)
  Future<void> migrateLocalAssetsToFirestore() async {
    try {
      final batch = _db.batch();
      final allAssetsMap = {
        'prop': RoomAssets.props,
        'wallpaper': RoomAssets.wallpapers,
        'background': RoomAssets.backgrounds,
        'floor': RoomAssets.floors,
        'emoticon': RoomAssets.emoticons,
      };

      for (var entry in allAssetsMap.entries) {
        final category = entry.key;
        final assetList = entry.value;

        for (var prop in assetList) {
          if (prop.imagePath != null && prop.imagePath!.startsWith('http'))
            continue;

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
              },
              SetOptions(merge: true));
        }
      }

      await batch.commit();
      debugPrint('로컬 소품 마이그레이션 완료!');
    } catch (e) {
      debugPrint('마이그레이션 오류: $e');
    }
  }

  Future<void> addNewAsset({
    required String id,
    required String name,
    required int price,
    required String category,
    required File imageFile,
    double sizeMultiplier = 1.0,
    double aspectRatio = 1.0,
    bool isWallMounted = false,
    bool noShadow = false,
    double shadowDyCorrection = 0.0,
    bool isLight = false,
    double lightIntensity = 1.0,
  }) async {
    try {
      // 이미지 화질 및 크기 유지한 채로 Storage 업로드
      final storageRef = _storage.ref().child('assets/$category/$id.png');
      await storageRef.putFile(
          imageFile, SettableMetadata(contentType: 'image/png'));
      final downloadUrl = await storageRef.getDownloadURL();

      // DB 텍스트 정보 저장
      final docRef = _db.collection('assets').doc(id);
      await docRef.set({
        'name': name,
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
    required int price,
    required String category,
    File? imageFile,
    required String existingImageUrl,
    double sizeMultiplier = 1.0,
    double aspectRatio = 1.0,
    bool isWallMounted = false,
    bool noShadow = false,
    double shadowDyCorrection = 0.0,
    bool isLight = false,
    double lightIntensity = 1.0,
  }) async {
    try {
      String downloadUrl = existingImageUrl;
      if (imageFile != null) {
        final storageRef = _storage.ref().child('assets/$category/$id.png');
        await storageRef.putFile(
            imageFile, SettableMetadata(contentType: 'image/png'));
        downloadUrl = await storageRef.getDownloadURL();
      }

      final docRef = _db.collection('assets').doc(id);
      await docRef.update({
        'name': name,
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

      debugPrint('에셋 [$id] 삭제 완료');
    } catch (e) {
      debugPrint('에셋 삭제 실패: $e');
      rethrow;
    }
  }
}
