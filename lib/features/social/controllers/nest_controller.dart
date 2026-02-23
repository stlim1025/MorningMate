import 'dart:async';
import 'package:flutter/material.dart';

import '../../../services/nest_service.dart';
import '../../../models/nest_model.dart';

class NestController extends ChangeNotifier {
  final NestService _nestService;

  NestController(this._nestService);

  List<NestModel> _myNests = [];
  List<NestModel> get myNests => _myNests;

  List<Map<String, dynamic>> _nestRequests = [];
  List<Map<String, dynamic>> get nestRequests => _nestRequests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<NestModel>>? _nestsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;

  void initialize(String userId) {
    _isLoading = true;
    notifyListeners();

    _nestsSubscription?.cancel();
    _nestsSubscription =
        _nestService.getUserNestsStream(userId).listen((nests) {
      _myNests = nests;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('둥지 스트림 에러 (무시됨): $e');
      _isLoading = false;
    });

    _requestsSubscription?.cancel();
    _requestsSubscription =
        _nestService.getReceivedNestInvitesStream(userId).listen((requests) {
      _nestRequests = requests;
      notifyListeners();
    }, onError: (e) {
      debugPrint('둥지 초대 스트림 에러 (무시됨): $e');
    });
  }

  @override
  void dispose() {
    _nestsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void clear() {
    _myNests = [];
    _nestRequests = [];
    _nestsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _nestsSubscription = null;
    _requestsSubscription = null;
    notifyListeners();
  }

  Future<String> createNest(String name, String creatorId) async {
    // 2. 둥지 만들기 개수 확인 (내가 만든 둥지가 최대 2개)
    int createdNestsCount =
        _myNests.where((nest) => nest.creatorId == creatorId).length;
    if (createdNestsCount >= 2) {
      throw Exception('최대 2개의 둥지만 만들 수 있습니다.');
    }

    final nestId = await _nestService.createNest(name, creatorId);
    return nestId;
  }

  Future<void> inviteToNest(String nestId, String nestName, String senderId,
      String receiverId) async {
    await _nestService.inviteToNest(nestId, nestName, senderId, receiverId);
  }

  Future<void> acceptNestInvite(
      String inviteId, String nestId, String userId) async {
    await _nestService.acceptNestInvite(inviteId, nestId, userId);
  }

  Future<void> rejectNestInvite(String inviteId) async {
    await _nestService.rejectNestInvite(inviteId);
  }

  Future<void> donateGaji(String nestId, String userId, String senderNickname,
      String nestName, int amount, int currentGaji) async {
    if (amount <= 0) {
      throw Exception('기부할 가지의 수를 정확히 입력해주세요.');
    }
    if (amount > currentGaji) {
      throw Exception('보유하고 있는 가지가 부족합니다.');
    }
    await _nestService.donateGaji(
        nestId, userId, senderNickname, nestName, amount);
  }

  Future<void> postNestMessage(String nestId, String userId,
      String senderNickname, String nestName, String message) async {
    if (message.trim().isEmpty) {
      throw Exception('한마디를 입력해주세요.');
    }
    await _nestService.postNestMessage(
        nestId, userId, senderNickname, nestName, message);
  }

  Future<void> updateNest(
      String nestId, String name, String description) async {
    if (name.trim().isEmpty) {
      throw Exception('둥지 이름을 입력해주세요.');
    }
    await _nestService.updateNest(nestId, name, description);
  }
}
