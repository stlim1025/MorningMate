const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// Set global options
setGlobalOptions({ maxInstances: 10 });

// 친구 깨우기 함수
exports.wakeUpFriend = onCall(async (request) => {
    // 인증 확인
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, friendId, friendName } = request.data;

    // 유효성 검사
    if (!userId || !friendId || !friendName) {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments."
        );
    }

    // 친구의 FCM 토큰 가져오기
    try {
        const friendDoc = await admin
            .firestore()
            .collection("users")
            .doc(friendId)
            .get();

        if (!friendDoc.exists) {
            throw new HttpsError("not-found", "Friend not found.");
        }

        const friendData = friendDoc.data();
        const fcmToken = friendData?.fcmToken;

        if (!fcmToken) {
            logger.info(`Friend ${friendId} does not have an FCM token.`);
            return { success: false, message: "Friend not reachable." };
        }

        // 알림 페이로드
        const message = {
            token: fcmToken,
            notification: {
                title: "일어나세요! ☀️",
                body: `${friendName}님이 당신을 깨우고 있어요!`,
            },
            data: {
                type: "wake_up",
                friendId: userId,
                friendName: friendName,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                },
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        sound: "default",
                    },
                },
            },
        };

        // 알림 전송
        await admin.messaging().send(message);
        logger.info(`Wake up notification sent to ${friendId} from ${userId}`);

        return { success: true };
    } catch (error) {
        logger.error("Error sending notification:", error);
        throw new HttpsError("internal", "Error sending notification.");
    }
});

// 친구 요청 알림 전송 함수
exports.sendFriendRequestNotification = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, friendId, senderNickname } = request.data;

    if (!userId || !friendId || !senderNickname) {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments."
        );
    }

    try {
        const friendDoc = await admin
            .firestore()
            .collection("users")
            .doc(friendId)
            .get();

        if (!friendDoc.exists) {
            throw new HttpsError("not-found", "Friend not found.");
        }

        const friendData = friendDoc.data();
        const fcmToken = friendData?.fcmToken;

        if (!fcmToken) {
            logger.info(`Friend ${friendId} does not have an FCM token.`);
            return { success: false, message: "Friend not reachable." };
        }

        const notificationMessage = {
            token: fcmToken,
            notification: {
                title: "친구 요청",
                body: `${senderNickname}님이 친구 요청을 보냈습니다! 👋`,
            },
            data: {
                type: "friend_request",
                senderId: userId,
                senderNickname: senderNickname,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                },
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        sound: "default",
                    },
                },
            },
        };

        await admin.messaging().send(notificationMessage);
        logger.info(`Friend request sent to ${friendId} from ${userId}`);

        return { success: true };
    } catch (error) {
        logger.error("Error sending friend request:", error);
        throw new HttpsError("internal", "Error sending friend request.");
    }
});

// 친구 요청 수락 알림 전송 함수
exports.sendFriendAcceptNotification = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, friendId, senderNickname } = request.data;

    if (!userId || !friendId || !senderNickname) {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments."
        );
    }

    try {
        const friendDoc = await admin
            .firestore()
            .collection("users")
            .doc(friendId)
            .get();

        if (!friendDoc.exists) {
            throw new HttpsError("not-found", "Friend not found.");
        }

        const friendData = friendDoc.data();
        const fcmToken = friendData?.fcmToken;

        if (!fcmToken) {
            logger.info(`Friend ${friendId} does not have an FCM token.`);
            return { success: false, message: "Friend not reachable." };
        }

        const notificationMessage = {
            token: fcmToken,
            notification: {
                title: "친구 요청 수락",
                body: `${senderNickname}님이 친구 요청을 수락했어요.`,
            },
            data: {
                type: "friend_accept",
                senderId: userId,
                senderNickname: senderNickname,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                },
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        sound: "default",
                    },
                },
            },
        };

        await admin.messaging().send(notificationMessage);
        logger.info(`Friend accept sent to ${friendId} from ${userId}`);

        return { success: true };
    } catch (error) {
        logger.error("Error sending friend accept:", error);
        throw new HttpsError("internal", "Error sending friend accept.");
    }
});

// 친구 요청 거절 알림 전송 함수
exports.sendFriendRejectNotification = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, friendId, senderNickname } = request.data;

    if (!userId || !friendId || !senderNickname) {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments."
        );
    }

    try {
        const friendDoc = await admin
            .firestore()
            .collection("users")
            .doc(friendId)
            .get();

        if (!friendDoc.exists) {
            throw new HttpsError("not-found", "Friend not found.");
        }

        const friendData = friendDoc.data();
        const fcmToken = friendData?.fcmToken;

        if (!fcmToken) {
            logger.info(`Friend ${friendId} does not have an FCM token.`);
            return { success: false, message: "Friend not reachable." };
        }

        const notificationMessage = {
            token: fcmToken,
            notification: {
                title: "친구 요청 거절",
                body: `${senderNickname}님이 친구 요청을 거절했어요.`,
            },
            data: {
                type: "friend_reject",
                senderId: userId,
                senderNickname: senderNickname,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                },
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        sound: "default",
                    },
                },
            },
        };

        await admin.messaging().send(notificationMessage);
        logger.info(`Friend reject sent to ${friendId} from ${userId}`);

        return { success: true };
    } catch (error) {
        logger.error("Error sending friend reject:", error);
        throw new HttpsError("internal", "Error sending friend reject.");
    }
});
