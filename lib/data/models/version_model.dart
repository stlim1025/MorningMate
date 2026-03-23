import 'package:cloud_firestore/cloud_firestore.dart';

class VersionModel {
  final String latestVersion;
  final String minimumVersion;
  final String updateTitle;
  final String updateBody;
  final String? updateTitleEn;
  final String? updateBodyEn;
  final String? updateTitleJa;
  final String? updateBodyJa;
  final bool isForceUpdate;

  VersionModel({
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateTitle,
    required this.updateBody,
    this.updateTitleEn,
    this.updateBodyEn,
    this.updateTitleJa,
    this.updateBodyJa,
    required this.isForceUpdate,
  });

  factory VersionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return VersionModel.fromMap(data);
  }

  factory VersionModel.fromMap(Map<String, dynamic>? data) {
    return VersionModel(
      latestVersion: data?['latestVersion'] ?? '1.0.0',
      minimumVersion: data?['minimumVersion'] ?? '1.0.0',
      updateTitle: data?['updateTitle'] ?? '업데이트 안내',
      updateBody: data?['updateBody'] ?? '새로운 버전이 출시되었습니다. 업데이트 후 이용해 주세요!',
      updateTitleEn: data?['updateTitleEn'],
      updateBodyEn: data?['updateBodyEn'],
      updateTitleJa: data?['updateTitleJa'],
      updateBodyJa: data?['updateBodyJa'],
      isForceUpdate: data?['isForceUpdate'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'latestVersion': latestVersion,
      'minimumVersion': minimumVersion,
      'updateTitle': updateTitle,
      'updateBody': updateBody,
      'updateTitleEn': updateTitleEn,
      'updateBodyEn': updateBodyEn,
      'updateTitleJa': updateTitleJa,
      'updateBodyJa': updateBodyJa,
      'isForceUpdate': isForceUpdate,
    };
  }
}
