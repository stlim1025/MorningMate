import 'package:cloud_firestore/cloud_firestore.dart';

class AdLogModel {
  final String? id;
  final String userId;
  final String userNickname;
  final String adType; // 'rewarded', 'bonus_rewarded', etc.
  final String adProvider; // 'AdMob', 'Unity', etc.
  final String? adNetworkClassName; // e.g., 'UnityAdapter'
  final String action; // 'load', 'show', 'reward'
  final DateTime timestamp;
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  AdLogModel({
    this.id,
    required this.userId,
    required this.userNickname,
    required this.adType,
    required this.adProvider,
    this.adNetworkClassName,
    required this.action,
    required this.timestamp,
    required this.success,
    this.errorCode,
    this.errorMessage,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userNickname': userNickname,
      'adType': adType,
      'adProvider': adProvider,
      'adNetworkClassName': adNetworkClassName,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'success': success,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
    };
  }

  factory AdLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userNickname: data['userNickname'] ?? '',
      adType: data['adType'] ?? '',
      adProvider: data['adProvider'] ?? '',
      adNetworkClassName: data['adNetworkClassName'],
      action: data['action'] ?? 'load', // 기본값 load (하위 호환)
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      success: data['success'] ?? false,
      errorCode: data['errorCode'],
      errorMessage: data['errorMessage'],
    );
  }
}
