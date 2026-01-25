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
