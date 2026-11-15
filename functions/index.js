// Trusted Cloud Quest backend.
//  - completeToday: awards the fixed reward exactly once (this file).
//  - askQuestCoach: supervised AI coach (Task 6).
//
// The Admin SDK bypasses Firestore security rules, so every function here
// must check authentication itself and only touch the caller's own data.
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

// Reward values live on the server only. Nothing the client sends can
// change them, and they are not stored in client-readable challenge data.
const CHALLENGE_ID = "today";
const REWARD_POINTS = 10;
const BADGE_ID = "first-quest";

export const completeToday = onCall(async (request) => {
  // 1. Identity comes from the verified Firebase Auth token, never the payload.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  // 2. Only the one known challenge can be completed. Any other client
  //    fields (uid, points, badgeId, ...) are ignored.
  if (request.data?.challengeId !== CHALLENGE_ID) {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  const uid = request.auth.uid;
  const challengeRef = db.doc(`challenges/${CHALLENGE_ID}`);
  const progressRef = db.doc(`users/${uid}/progress/${CHALLENGE_ID}`);

  // 3. Transaction: read existing progress and write the reward atomically,
  //    so retries or double taps can never award points twice.
  return db.runTransaction(async (transaction) => {
    const [challenge, progress] = await Promise.all([
      transaction.get(challengeRef),
      transaction.get(progressRef),
    ]);
    if (!challenge.exists) {
      throw new HttpsError("failed-precondition", "No challenge is available today.");
    }
    if (progress.exists) {
      const existing = progress.data();
      return {
        completed: true,
        points: existing.points,
        badgeId: existing.badgeId,
        alreadyCompleted: true,
      };
    }
    const reward = {
      completed: true,
      points: REWARD_POINTS,
      badgeId: BADGE_ID,
      completedAt: FieldValue.serverTimestamp(),
    };
    transaction.set(progressRef, reward);
    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false,
    };
  });
});

// Supervised AI coach (read-only tool; cannot award rewards).
export { askQuestCoach } from "./questCoach.js";
