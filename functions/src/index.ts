/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

// Set global options
setGlobalOptions({ maxInstances: 10 });

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
      { merge: true }
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
  senderNickname?: string,
  isReply?: boolean
) => {
  const isEn = lang === "en";
  const name = (senderNickname && senderNickname.trim() !== "") ? senderNickname : (isEn ? "Friend" : "친구");

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
      if (isReply) {
        return {
          title: isEn ?
            `${name} sent a reply!` :
            `${name}님이 답장을 보냈습니다!`,
          body: message ?? (isEn ? "Sent a reply." : "답장이 도착했어요."),
        };
      }
      return {
        title: isEn ?
          `${name} sent a cheer message!` :
          `${name}님이 응원 메시지를 보냈습니다!`,
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
    const { title, body } = buildNotificationContent(
      normalizedType,
      userLang,
      data.message,
      data.senderNickname,
      data.isReply === true || data.isReply === "true"
    );

    logger.info(`Sending notification to user ${userId}: Title="${title}", Body="${body}", Type="${normalizedType}"`);

    const messagePayload = {
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
          title, // Explicitly set to override any system defaults
          body,
          channelId: "high_importance_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            contentAvailable: true,
            sound: "default",
          },
        },
      },
    };

    try {
      await admin.messaging().send(messagePayload);
      logger.info(`Successfully sent notification to user ${userId}`);
    } catch (e) {
      logger.error(`Error sending notification to user ${userId}:`, e);
    }
    await snapshot.ref.update({ fcmSent: true });
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

  const { userId, friendId } = request.data;

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
      return { success: false, message: "Friend not reachable." };
    }

    logger.info(`Wake up check passed for ${friendId} from ${userId}`);
    return { success: true };
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

  const { userId, friendId, message } = request.data;

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

    logger.info(`Cheer message check passed for ${friendId} from ${userId}`);
    return { success: true };
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

    logger.info(`Friend request check passed for ${friendId} from ${userId}`);
    return { success: true };
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

    logger.info(`Friend accept check passed for ${friendId} from ${userId}`);
    return { success: true };
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

    logger.info(`Friend reject check passed for ${friendId} from ${userId}`);
    return { success: true };
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
    const { title, body } = buildNotificationContent("morning_reminder", userLang);

    const messagePayload = {
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
          title,
          body,
          channelId: "high_importance_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            contentAvailable: true,
            sound: "default",
          },
        },
      },
    };

    try {
      await admin.messaging().send(messagePayload);
      logger.info(`Sent morning reminder to user ${userId}`);
    } catch (error) {
      logger.error(`Error sending reminder to user ${userId}:`, error);
    }
  });

  await Promise.all(promises);
});

// 관리자 푸시 전송 처리 (push_history 컬렉션에 새 문서 생성 시 동작)
export const processAdminPushRequest = onDocumentCreated("push_history/{pushId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data() as any;
  if (data.status === 'processed') return;

  try {
    const { title, body, target, deepLink } = data;
    const rawReward = data.rewardGaji;
    let rewardGaji = 0;
    if (typeof rawReward === 'number') {
      rewardGaji = rawReward;
    } else {
      rewardGaji = parseInt(String(rawReward || '0'), 10);
    }
    if (isNaN(rewardGaji)) rewardGaji = 0;

    let tokens: string[] = [];
    let userIds: string[] = [];
    logger.info(`[Admin Push] Starting processing: title="${title}", target="${target}", rewardGaji=${rewardGaji}`);

    // Parse target: "baseTarget:country:CODE" or just "baseTarget"
    let baseTarget = target;
    let countryCodeFilter: string | null = null;

    if (target && target.includes(':country:')) {
      const parts = target.split(':country:');
      baseTarget = parts[0];
      countryCodeFilter = parts[1];
    }

    // 1. 타겟 대상 유저 토큰 및 ID 가져오기
    const usersRef = admin.firestore().collection("users");
    
    // In-memory filter flags
    let checkCountry = false;
    let targetCountryCode = '';
    if (countryCodeFilter && countryCodeFilter !== 'all') {
      checkCountry = true;
      targetCountryCode = countryCodeFilter;
    }

    if (baseTarget === 'all') {
      let query: admin.firestore.Query = usersRef.where("fcmToken", ">", "");
      if (checkCountry) {
        query = query.where("countryCode", "==", targetCountryCode);
      }
      const users = await query.get();
      users.docs.forEach(doc => {
        const d = doc.data();
        userIds.push(doc.id);
        if (d.fcmToken) tokens.push(d.fcmToken);
      });
    } else if (baseTarget === 'inactive_3days') {
      // 3일 전
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
      // fcmToken 필터링(부등호)과 중복될 수 없으므로 lastLoginDate 조건만으로 쿼리 후 인메모리 필터링
      const users = await usersRef.where("lastLoginDate", "<", admin.firestore.Timestamp.fromDate(threeDaysAgo)).get();
      users.docs.forEach(doc => {
        const d = doc.data();
        if (checkCountry && d.countryCode !== targetCountryCode) return;
        userIds.push(doc.id);
        if (d.fcmToken) tokens.push(d.fcmToken);
      });
    } else if (baseTarget === 'consecutive_10days') {
      const users = await usersRef.where("consecutiveDays", ">=", 10).get();
      users.docs.forEach(doc => {
        const d = doc.data();
        if (checkCountry && d.countryCode !== targetCountryCode) return;
        userIds.push(doc.id);
        if (d.fcmToken) tokens.push(d.fcmToken);
      });
    } else if (baseTarget && baseTarget.startsWith('uid:')) {
      const specificUser = baseTarget.replace('uid:', '');
      // 이메일 또는 UID로 검색
      if (specificUser.includes('@')) {
        const users = await usersRef.where("email", "==", specificUser).limit(1).get();
        if (!users.empty) {
          const ud = users.docs[0].data();
          userIds.push(users.docs[0].id);
          if (ud.fcmToken) {
            tokens.push(ud.fcmToken);
          }
        }
      } else {
        const userDoc = await usersRef.doc(specificUser).get();
        if (userDoc.exists) {
          userIds.push(userDoc.id);
          const userData = userDoc.data();
          if (userData?.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        }
      }
    } else if (baseTarget && baseTarget.startsWith('uids:')) {
      const uidsStr = baseTarget.replace('uids:', '');
      const uids = uidsStr.split(',').map((u: string) => u.trim()).filter((u: string) => u.length > 0);

      // 여러 유저의 정보를 병렬로 가져오기
      const userPromises = uids.map(async (id: string) => {
        if (id.includes('@')) {
          const snap = await usersRef.where("email", "==", id).limit(1).get();
          return !snap.empty ? { id: snap.docs[0].id, data: snap.docs[0].data() } : null;
        } else {
          const doc = await usersRef.doc(id).get();
          return doc.exists ? { id: doc.id, data: doc.data() } : null;
        }
      });

      const results = await Promise.all(userPromises);
      results.forEach((r) => {
        if (r) {
          userIds.push(r.id);
          if (r.data?.fcmToken) {
            tokens.push(r.data.fcmToken);
          }
        }
      });
    }

    // 중복 토큰 및 ID 제거
    tokens = [...new Set(tokens)];
    const uniqueUserIds = [...new Set(userIds)];

    // 2. 가지 보상 지급 (userIds 기준)
    if (rewardGaji > 0 && uniqueUserIds.length > 0) {
      logger.info(`[Admin Push] Starting reward distribution for ${uniqueUserIds.length} users. Reward: ${rewardGaji} gaji.`);
      // 유저 1명당 3개의 작업(update, history set, noti set)이 있으므로 batch 한도를 고려하여 150명씩 처리
      const batchLimit = 150;
      for (let i = 0; i < uniqueUserIds.length; i += batchLimit) {
        const batch = admin.firestore().batch();
        const chunk = uniqueUserIds.slice(i, i + batchLimit);
        const notificationsRef = admin.firestore().collection('notifications');
        
        chunk.forEach(uid => {
          // 1) 포인트 업데이트
          batch.update(usersRef.doc(uid), {
            points: admin.firestore.FieldValue.increment(rewardGaji)
          });

          // 2) 포인트 내역 저장 (가지 사용 내역 페이지용)
          const historyRef = admin.firestore().collection('point_history').doc();
          batch.set(historyRef, {
            userId: uid,
            type: 'admin_reward',
            description: '운영자 보상',
            amount: rewardGaji,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // 3) 최상위 알림 생성 (알림함용)
          const notiRef = notificationsRef.doc();
          batch.set(notiRef, {
            id: notiRef.id,
            userId: uid,
            senderId: 'admin',
            senderNickname: '운영자',
            type: 'system', // system 타입 사용
            message: `[운영자 보상] 가지 ${rewardGaji}개가 지급되었습니다.`,
            isRead: false,
            fcmSent: true,
            isReplied: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: { 
              type: 'admin_push', 
              rewardGaji: rewardGaji,
              deepLink: deepLink || ""
            }
          });
        });
        await batch.commit();
      }
      logger.info(`[Admin Push] Successfully rewarded ${uniqueUserIds.length} users.`);
    }

    if (tokens.length === 0) {
      logger.info(`[Admin Push] No valid tokens found for target: ${target}`);
      await snapshot.ref.update({ status: 'processed', note: 'No valid tokens but reward processed' });
      return;
    }

    const finalBody = rewardGaji > 0 ? `${body}\n\n가지 ${rewardGaji}개가 지급되었습니다.` : body;

    // 2. FCM 발송 데이터 준비
    const payload: any = {
      notification: {
        title: title,
        body: finalBody,
      },
      data: {
        type: "admin_push",
        title: title, // 포그라운드 알림용
        body: finalBody,   // 포그라운드 알림용
        deepLink: deepLink || "",
        rewardGaji: String(rewardGaji),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          title: title,
          body: finalBody,
          channelId: "high_importance_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            sound: "default",
            alert: {
              title: title,
              body: finalBody,
            },
          },
        },
      },
    };

    // sendEachForMulticast 최대 한도는 500개
    const chunkSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      const chunkPayload = { ...payload, tokens: chunk };
      const response = await admin.messaging().sendEachForMulticast(chunkPayload);
      successCount += response.successCount;
      failureCount += response.failureCount;
    }

    logger.info(`[Admin Push] Sent to ${tokens.length} tokens. Success: ${successCount}, Failure: ${failureCount}`);

    // 3. 발송 완료 처리
    await snapshot.ref.update({
      status: 'processed',
      successCount: successCount,
      failureCount: failureCount
    });

  } catch (error: any) {
    logger.error(`[Admin Push] Error:`, error);
    await snapshot.ref.update({ status: 'error', error: error.toString() });
  }
});
