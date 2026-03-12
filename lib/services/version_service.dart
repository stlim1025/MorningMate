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

      // 2. Get version info from Firestore
      final doc = await _firestore.collection('settings').doc('version').get();
      if (!doc.exists) {
        return VersionCheckResult(type: VersionUpdateType.none);
      }

      final info = VersionModel.fromFirestore(doc);

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
