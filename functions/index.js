const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { initializeApp } = require("firebase-admin/app");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ── #3: Notify members when invite is created ──

exports.onInviteCreated = onDocumentCreated("invites/{tokenId}", async (event) => {
  const data = event.data.data();
  const accountId = data.account_id;
  const createdBy = data.created_by;

  const accountSnap = await db.doc(`accounts/${accountId}`).get();
  if (!accountSnap.exists) return;

  const account = accountSnap.data();
  const memberIds = account.member_ids || [];

  // Get FCM tokens for all members except creator
  const tokens = [];
  for (const memberId of memberIds) {
    if (memberId === createdBy) continue;
    const tokenSnap = await db.collection(`users/${memberId}/fcm_tokens`).get();
    tokenSnap.forEach((doc) => tokens.push(doc.data().token));
  }

  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: account.name || "Family",
      body: "You have a new invite link",
    },
    data: {
      type: "invite",
      token_id: event.params.tokenId,
    },
  });
});

// ── #4: Notify family members when transaction is created ──

exports.onTransactionCreated = onDocumentCreated(
  "accounts/{accountId}/transactions/{txnId}",
  async (event) => {
    const data = event.data.data();
    const accountId = event.params.accountId;
    const createdBy = data.created_by;
    const amount = data.amount || 0;
    const type = data.type || "expense";

    // Only notify for family accounts
    const accountSnap = await db.doc(`accounts/${accountId}`).get();
    if (!accountSnap.exists) return;

    const account = accountSnap.data();
    if (account.type !== "family") return;

    const memberIds = account.member_ids || [];

    const tokens = [];
    for (const memberId of memberIds) {
      if (memberId === createdBy) continue;
      const tokenSnap = await db.collection(`users/${memberId}/fcm_tokens`).get();
      tokenSnap.forEach((doc) => tokens.push(doc.data().token));
    }

    if (tokens.length === 0) return;

    const action = type === "income" ? "earned" : "spent";

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: account.name || "Family",
        body: `New ${action}: ${amount.toLocaleString()}`,
      },
      data: {
        type: "transaction",
        account_id: accountId,
      },
    });
  }
);
