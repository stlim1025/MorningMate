/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

// Set global options
setGlobalOptions({maxInstances: 10});

const RATE_LIMIT_WINDOW_MS = 30 * 1000;

async function enforceRateLimit(
  userId: string,
  friendId: string,
  type: string
) {
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
      {merge: true}
    );
  });
}

const normalizeNotificationType = (type?: string) => {
  switch (type) {
  case "wakeUp":
    return "wake_up";
  case "friendRequest":
    return "friend_request";
  case "cheerMessage":
    return "cheer_message";
  case "nestInvite":
    return "nest_invite";
  case "nestDonation":
    return "nest_donation";
  case "reportResult":
    return "report_result";
  case "nestPoke":
    return "nest_poke";
  case "memoLike":
    return "memo_like";
  case "morning_diary":
  case "morning_reminder":
    return "morning_reminder";
  case "system":
    return "system";
  default:
    return type ?? "system";
  }
};

const buildNotificationContent = (
  type: string,
  lang = "ko",
  message?: string,
  senderNickname?: string
) => {
  const isEn = lang === "en";
  const name = senderNickname ?? (isEn ? "Friend" : "친구");

  switch (type) {
  case "wake_up":
    return {
      title: isEn ? "Wake Up Alert" : "깨우기 알림",
      body: isEn ?
        `${name} is waking you up! ⏰` :
        `${name}님이 당신을 깨우고 있어요!`,
    };
  case "friend_request":
    return {
      title: isEn ? "Friend Request" : "친구 요청",
      body: isEn ?
        `${name} sent you a friend request! 👋` :
        `${name}님이 친구 요청을 보냈습니다! 👋`,
    };
  case "friend_accept":
    return {
      title: isEn ? "Friend Request Accepted" : "친구 요청 수락",
      body: isEn ?
        `${name} accepted your friend request.` :
        `${name}님이 친구 요청을 수락했어요.`,
    };
  case "friend_reject":
    return {
      title: isEn ? "Friend Request Rejected" : "친구 요청 거절",
      body: isEn ?
        `${name} rejected your friend request.` :
        `${name}님이 친구 요청을 거절했어요.`,
    };
  case "cheer_message":
    return {
      title: isEn ? "Cheer Message" : "응원 메시지",
      body: message ?? (isEn ? "Sent a cheer message." : "응원 메시지가 도착했어요."),
    };
  case "nest_invite":
    return {
      title: isEn ? "Nest Invitation" : "둥지 초대",
      body: isEn ?
        `${name} invited you to a nest!` :
        `${name}님이 둥지에 초대했습니다!`,
    };
  case "nest_donation":
    return {
      title: isEn ? "Nest Donation" : "둥지 기부 알림",
      body: isEn ?
        "A new donation arrived at the nest." :
        "둥지에 새로운 기부가 도착했습니다.",
    };
  case "report_result":
    return {
      title: isEn ? "Report Result" : "신고 처리 결과",
      body: isEn ?
        "Your report has been processed." :
        "신고하신 건에 대한 처리 결과가 도착했습니다.",
    };
  case "nest_poke":
    return {
      title: isEn ? "Poke Alert" : "찌르기 알림",
      body: isEn ?
        `${name} poked you! 👉` :
        `${name}님이 당신을 찔렀습니다! 👉`,
    };
  case "memo_like":
    return {
      title: isEn ? "Memo Heart" : "메모 하트",
      body: isEn ?
        `${name} sent a heart to your memo! ❤️` :
        `${name}님이 내 메모에 하트를 보냈어요! ❤️`,
    };
  case "morning_reminder":
    return {
      title: isEn ? "Good Morning!" : "아침 일기",
      body: isEn ?
        "It's time to write your diary and wake up your character! ☀️" :
        "일기를 작성하고 캐릭터를 깨워주세요! ☀️",
    };
  case "system":
  default:
    return {
      title: isEn ? "Notification" : "알림",
      body: message ?? (isEn ? "You have a new notification." : "새로운 알림이 도착했어요."),
    };
  }
};

export const sendNotificationOnCreate = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data() as Record<string, any>;
    if (data.fcmSent === true) {
      return;
    }

    const userId = data.userId as string | undefined;
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

    const userLang = userData?.languageCode ?? "ko";

    const normalizedType = normalizeNotificationType(data.type);
    const {title, body} = buildNotificationContent(
      normalizedType,
      userLang,
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
        priority: "high" as const,
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
    await snapshot.ref.update({fcmSent: true});
  }
);

// 친구 깨우기 함수
export const wakeUpFriend = onCall(async (request) => {
  // 인증 확인
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {userId, friendId} = request.data;

  // 유효성 검사
  if (!userId || !friendId) {
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
      return {success: false, message: "Friend not reachable."};
    }

    logger.info(`Wake up check passed for ${friendId} from ${userId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error sending notification:", error);
    throw new HttpsError("internal", "Error sending notification.");
  }
});

// 응원 메시지 전송 함수
export const sendCheerMessage = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {userId, friendId, message} = request.data;

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
      return {success: false, message: "Friend not reachable."};
    }

    logger.info(`Cheer message check passed for ${friendId} from ${userId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error sending cheer message:", error);
    throw new HttpsError("internal", "Error sending cheer message.");
  }
});

// 친구 요청 알림 전송 함수
export const sendFriendRequestNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {userId, friendId, senderNickname} = request.data;

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
      return {success: false, message: "Friend not reachable."};
    }

    logger.info(`Friend request check passed for ${friendId} from ${userId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error sending friend request:", error);
    throw new HttpsError("internal", "Error sending friend request.");
  }
});

// 친구 요청 수락 알림 전송 함수
export const sendFriendAcceptNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {userId, friendId, senderNickname} = request.data;

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
      return {success: false, message: "Friend not reachable."};
    }

    logger.info(`Friend accept check passed for ${friendId} from ${userId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error sending friend accept:", error);
    throw new HttpsError("internal", "Error sending friend accept.");
  }
});

// 친구 요청 거절 알림 전송 함수
export const sendFriendRejectNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {userId, friendId, senderNickname} = request.data;

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
      return {success: false, message: "Friend not reachable."};
    }

    logger.info(`Friend reject check passed for ${friendId} from ${userId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error sending friend reject:", error);
    throw new HttpsError("internal", "Error sending friend reject.");
  }
});

// 아침 일기 작성 알림 예약 함수 (매 5분마다 실행)
export const morningReminder = onSchedule("every 5 minutes", async () => {
  const now = new Date();
  // 한국 시간 (UTC+9) 기준 시간 계산
  const krTime = new Date(now.getTime() + (9 * 60 * 60 * 1000));
  const hours = krTime.getUTCHours().toString().padStart(2, "0");
  const minutes = krTime.getUTCMinutes().toString().padStart(2, "0");
  const currentTimeStr = `${hours}:${minutes}`;

  logger.info(`Running morningReminder at ${currentTimeStr} (KR Time)`);

  const usersRef = admin.firestore().collection("users");
  // 알림이 켜져 있는 사용자 쿼리
  const snapshot = await usersRef
    .where("morningDiaryNoti", "==", true)
    .where("morningDiaryNotiTime", "==", currentTimeStr)
    .get();

  if (snapshot.empty) {
    logger.info("No users to remind at this time.");
    return;
  }

  const todayStr = krTime.toISOString().split("T")[0]; // YYYY-MM-DD

  const promises = snapshot.docs.map(async (doc) => {
    const userData = doc.data();
    const userId = doc.id;

    // 오늘 이미 일기를 썼는지 확인
    if (userData.lastDiaryDate) {
      const lastDate = userData.lastDiaryDate.toDate();
      const lastDateKR = new Date(lastDate.getTime() + (9 * 60 * 60 * 1000));
      const lastDateStr = lastDateKR.toISOString().split("T")[0];

      if (lastDateStr === todayStr) {
        logger.info(`User ${userId} already wrote a diary today.`);
        return;
      }
    }

    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const userLang = userData.languageCode ?? "ko";
    const {title, body} = buildNotificationContent("morning_reminder", userLang);

    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        type: "morning_reminder",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high" as const,
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

    try {
      await admin.messaging().send(message);
      logger.info(`Sent morning reminder to user ${userId}`);
    } catch (error) {
      logger.error(`Error sending reminder to user ${userId}:`, error);
    }
  });

  await Promise.all(promises);
});
