import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/models/version_model.dart';
import '../core/utils/version_utils.dart';

class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VersionCheckResult> checkVersion() async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('DEBUG: Version Check - currentVersion: $currentVersion');

      // 2. Get version info from Firestore
      final doc = await _firestore.collection('settings').doc('version').get();
      if (!doc.exists) {
        debugPrint('DEBUG: Version Check - Firestore doc does not exist');
        return VersionCheckResult(type: VersionUpdateType.none);
      }

      final data = doc.data();
      final platformKey = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      debugPrint('DEBUG: Version Check - platformKey: $platformKey');
      
      VersionModel info;
      if (data != null && data.containsKey(platformKey)) {
        info = VersionModel.fromMap(data[platformKey]);
        debugPrint('DEBUG: Version Check - latestVersion: ${info.latestVersion}, minimumVersion: ${info.minimumVersion}');
      } else {
        // Fallback to legacy structure
        info = VersionModel.fromFirestore(doc);
        debugPrint('DEBUG: Version Check - Fallback to legacy structure');
      }

      // 3. Compare versions
      if (VersionUtils.isUpdateRequired(currentVersion, info.minimumVersion)) {
        return VersionCheckResult(
          type: VersionUpdateType.force,
          info: info,
        );
      } else if (VersionUtils.isUpdateRecommended(currentVersion, info.latestVersion)) {
        return VersionCheckResult(
          type: info.isForceUpdate ? VersionUpdateType.force : VersionUpdateType.recommended,
          info: info,
        );
      }

      return VersionCheckResult(type: VersionUpdateType.none);
    } catch (e) {
      print('Version check error: $e');
      return VersionCheckResult(type: VersionUpdateType.none);
    }
  }
}

enum VersionUpdateType { force, recommended, none }

class VersionCheckResult {
  final VersionUpdateType type;
  final VersionModel? info;

  VersionCheckResult({required this.type, this.info});
}
