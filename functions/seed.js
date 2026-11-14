// Seeds the shared challenge document into the Firestore EMULATOR.
//
// Usage (from the project root, emulators already running):
//   npm --prefix functions run seed
//
// Safety: this script always targets the local emulator (default
// 127.0.0.1:8080), so it can never write to the production database.
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";

initializeApp({ projectId: "cloudquest-751db" });
const db = getFirestore();

// Reward values are intentionally NOT stored here: the trusted
// completeToday function owns the fixed 10 points + "first-quest" badge.
const challenge = {
  title: "Guard the Treasure",
  prompt:
    "In one or two sentences, explain why Cloud Quest awards points from a " +
    "Cloud Function instead of letting the app write its own score.",
};

await db.doc("challenges/today").set(challenge);
console.log(
  `Seeded challenges/today in ${process.env.FIRESTORE_EMULATOR_HOST}:`,
  challenge
);
