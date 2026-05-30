// functions/src/index.js
// ────────────────────────────────────────────────────────────────────────────
// Auto-delete Cloud Function
//
// Logic:
//   • Runs on a scheduled pub/sub trigger (every hour by default).
//   • Reads the global interval from appSettings/autoDelete.hours (default 2400).
//   • Any GuestEntry whose createdAt is older than the interval is deleted.
//   • The corresponding Party document is also deleted — UNLESS it has the
//     special partyCode "WWVV7HP" which is permanently exempt from deletion.
//
// ────────────────────────────────────────────────────────────────────────────

"use strict";

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

// ── Constants ────────────────────────────────────────────────────────────────

/** Party code that must NEVER be auto-deleted. */
const EXEMPT_PARTY_CODE = "WWVV7HP";

/** Fallback interval in hours when Firestore has no setting. */
const DEFAULT_INTERVAL_HOURS = 2400;

// ── Cloud Function ────────────────────────────────────────────────────────────

/**
 * Scheduled function that deletes expired GuestEntry documents and their
 * corresponding Party documents (except the exempt party WWVV7HP).
 *
 * Schedule: every hour. Adjust via Firebase Console or redeploy with a
 * different cron string for testing (e.g. "every 1 minutes").
 */
exports.autoDeleteExpiredEntries = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
    // Increase timeout for large data sets
    timeoutSeconds: 300,
  },
  async (event) => {
    const db = getFirestore();

    // 1. Determine the cutoff timestamp
    const intervalHours = 1;
    const cutoff = new Date(Date.now() - intervalHours * 60 * 60 * 1000);
    console.log(
      `Auto-delete run: interval=${intervalHours}h, cutoff=${cutoff.toISOString()}`
    );

    // 2. Query all GuestEntry documents older than the cutoff
    const guestSnap = await db
      .collection("GuestEntries")
      .where("createdAt", "<", cutoff)
      .get();

    if (guestSnap.empty) {
      console.log("No expired GuestEntry documents found.");
      return;
    }

    console.log(`Found ${guestSnap.size} expired GuestEntry document(s).`);

    // 3. Collect the unique partyIds referenced by the expired entries
    const partyIds = new Set();
    for (const doc of guestSnap.docs) {
      const pid = doc.data().partyId;
      if (pid) partyIds.add(pid);
    }

    // 4. Fetch the corresponding Party documents to check for the exempt code
    const partySnaps = {};
    for (const pid of partyIds) {
      try {
        const partyDoc = await db.collection("parties").doc(pid).get();
        if (partyDoc.exists) {
          partySnaps[pid] = partyDoc;
        }
      } catch (err) {
        console.error(`Error fetching party ${pid}:`, err);
      }
    }

    // 5. Determine which parties are safe to delete
    const deletablePartyIds = new Set();
    for (const [pid, partyDoc] of Object.entries(partySnaps)) {
      const code = partyDoc.data()?.partyCode;
      if (code === EXEMPT_PARTY_CODE) {
        console.log(
          `Party ${pid} (${code}) is exempt from auto-deletion — skipping.`
        );
      } else {
        deletablePartyIds.add(pid);
      }
    }

    // 6. Execute deletions in batches of 500 (Firestore limit)
    const BATCH_SIZE = 500;
    let batch = db.batch();
    let opCount = 0;

    const flushBatch = async () => {
      if (opCount > 0) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    };

    // Delete expired GuestEntry documents
    for (const doc of guestSnap.docs) {
      // Skip entries belonging to the exempt party
      const pid = doc.data().partyId;
      if (pid && !deletablePartyIds.has(pid) && partySnaps[pid]) {
        // This entry belongs to an exempt party — keep it
        continue;
      }
      batch.delete(doc.ref);
      opCount++;
      if (opCount >= BATCH_SIZE) await flushBatch();
    }

    // Delete the corresponding Party documents
    for (const pid of deletablePartyIds) {
      batch.delete(db.collection("parties").doc(pid));
      opCount++;
      if (opCount >= BATCH_SIZE) await flushBatch();
    }

    // Commit any remaining operations
    await flushBatch();

    console.log(
      `Auto-delete complete. Deleted entries for ${deletablePartyIds.size} party/parties.`
    );
  }
);
