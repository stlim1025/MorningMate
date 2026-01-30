const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// Set global options
setGlobalOptions({ maxInstances: 10 });

const RATE_LIMIT_WINDOW_MS = 30 * 1000;

const enforceRateLimit = async (userId, friendId, type) => {
    const rateLimitRef = admin
        .firestore()
        .collection("rate_limits")
        .doc(`${userId}_${friendId}_${type}`);

    await admin.firestore().runTransaction(async (transaction) => {
        const snapshot = await transaction.get(rateLimitRef);
        const now = Date.now();
        if (snapshot.exists) {
            const lastSentAt = snapshot.data()?.lastSentAt;
            const lastMillis = lastSentAt?.toMillis ? lastSentAt.toMillis() : null;
            if (lastMillis && now - lastMillis < RATE_LIMIT_WINDOW_MS) {
                throw new HttpsError(
                    "resource-exhausted",
                    "Too many requests. Please try again later."
                );
            }
        }

        transaction.set(
            rateLimitRef,
            {
                userId,
                friendId,
                type,
                lastSentAt: admin.firestore.Timestamp.fromMillis(now),
            },
            { merge: true }
        );
    });
};

const normalizeNotificationType = (type) => {
    switch (type) {
        case "wakeUp":
            return "wake_up";
        case "friendRequest":
            return "friend_request";
        case "cheerMessage":
            return "cheer_message";
        case "system":
            return "system";
        default:
            return type ?? "system";
    }
};

const buildNotificationContent = (type, message, senderNickname) => {
    switch (type) {
        case "wake_up":
            return {
                title: "깨우기 알림",
                body: message ?? `${senderNickname ?? "친구"}님이 당신을 깨우고 있어요!`,
            };
        case "friend_request":
            return {
                title: "친구 요청",
                body: message ?? `${senderNickname ?? "친구"}님이 친구 요청을 보냈습니다! 👋`,
            };
        case "cheer_message":
            return {
                title: "친구가 응원 메시지를 보냈어요.",
                body: message ?? "응원 메시지가 도착했어요.",
            };
        case "system":
        default:
            return {
                title: "알림",
                body: message ?? "새로운 알림이 도착했어요.",
            };
    }
};

exports.sendNotificationOnCreate = onDocumentCreated("notifications/{notificationId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        return;
    }

    const data = snapshot.data();
    if (data.fcmSent === true) {
        return;
    }

    const userId = data.userId;
    if (!userId) {
        logger.info("Notification without userId, skipping.", {
            notificationId: snapshot.id,
        });
        return;
    }

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
        logger.info(`User ${userId} does not have an FCM token.`);
        return;
    }

    const normalizedType = normalizeNotificationType(data.type);
    const { title, body } = buildNotificationContent(
        normalizedType,
        data.message,
        data.senderNickname
    );

    const message = {
        token: fcmToken,
        notification: {
            title,
            body,
        },
        data: {
            type: normalizedType,
            senderId: data.senderId ?? "",
            senderNickname: data.senderNickname ?? "",
            message: data.message ?? "",
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

    await admin.messaging().send(message);
    await snapshot.ref.update({ fcmSent: true });
});

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
        await enforceRateLimit(userId, friendId, "wake_up");

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

// 응원 메시지 전송 함수
exports.sendCheerMessage = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, friendId, message, senderNickname } = request.data;

    if (!userId || !friendId || !message) {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments."
        );
    }

    try {
        await enforceRateLimit(userId, friendId, "cheer_message");

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
                title: "친구가 응원 메시지를 보냈어요.",
                body: message,
            },
            data: {
                type: "cheer_message",
                senderId: userId,
                senderNickname: senderNickname ?? "",
                message: message,
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
        logger.info(`Cheer message sent to ${friendId} from ${userId}`);

        return { success: true };
    } catch (error) {
        logger.error("Error sending cheer message:", error);
        throw new HttpsError("internal", "Error sending cheer message.");
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
