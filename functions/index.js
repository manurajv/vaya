/**
 * VAYA – Firebase Cloud Functions
 * Node 22 · firebase-admin ^13 · firebase-functions ^6
 *
 * Deploy:   firebase deploy --only functions,firestore:rules,firestore:indexes,storage
 * Emulate:  firebase emulators:start --only functions,firestore,storage
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated, onDocumentCreated, onDocumentWritten } =
  require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

// ═════════════════════════════════════════════════════════════════════════════
// 1. SCHEDULED — Expire groups every 15 minutes
// ═════════════════════════════════════════════════════════════════════════════
exports.expireGroups = onSchedule('every 15 minutes', async () => {
  const now = new Date();

  const snapshot = await db
    .collection('groups')
    .where('status', '==', 'active')
    .where('deadline', '<', now)
    .get();

  if (snapshot.empty) return;

  const batch = db.batch();
  const notifications = [];

  for (const doc of snapshot.docs) {
    const group = doc.data();

    batch.update(doc.ref, {
      status: 'expired',
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Notify all members
    for (const member of group.members ?? []) {
      notifications.push({
        userId: member.userId,
        title: '⏰ Group Expired',
        body: `Your group for "${group.productName}" has expired. See your options.`,
        data: { type: 'group_update', route: `/group-expired/${doc.id}`, groupId: doc.id },
      });
    }

    // Notify the supplier too
    if (group.supplierId) {
      notifications.push({
        userId: group.supplierId,
        title: '⏰ Group Expired',
        body: `A group for "${group.productName}" has expired without reaching the target.`,
        data: { type: 'group_update', route: `/supplier`, groupId: doc.id },
      });
    }
  }

  await batch.commit();
  await Promise.allSettled(notifications.map((n) => notifyUser(n.userId, n)));
  console.log(`Expired ${snapshot.size} group(s).`);
});

// ═════════════════════════════════════════════════════════════════════════════
// 2. TRIGGER — Group completed → create orders + notify everyone
// ═════════════════════════════════════════════════════════════════════════════
exports.onGroupCompleted = onDocumentUpdated('groups/{groupId}', async (event) => {
  const before = event.data.before.data();
  const after  = event.data.after.data();
  const groupId = event.params.groupId;

  if (before.status === after.status || after.status !== 'completed') return;

  const batch = db.batch();
  const buyerNotifications = [];

  for (const member of after.members ?? []) {
    const activeTier  = getActiveTier(after.pricingTiers, after.totalQuantity);
    const pricePerUnit = activeTier?.pricePerUnit ?? 0;
    const totalAmount  = pricePerUnit * member.quantity;
    const tokenAmount  = totalAmount * ((after.tokenPercentage ?? 10) / 100);

    const orderRef = db.collection('orders').doc();
    batch.set(orderRef, {
      groupId,
      productId:          after.productId,
      productName:        after.productName,
      productImageUrl:    after.productImageUrl ?? null,
      buyerId:            member.userId,
      buyerBusinessName:  member.businessName,
      supplierId:         after.supplierId,
      supplierName:       after.supplierName,
      quantity:           member.quantity,
      pricePerUnit,
      totalAmount,
      tokenAmount,
      status:             'pending',
      paymentStatus:      'pending',
      createdAt:          FieldValue.serverTimestamp(),
      updatedAt:          FieldValue.serverTimestamp(),
    });

    buyerNotifications.push({
      userId: member.userId,
      title: '🎉 Group Completed!',
      body: `Your group for "${after.productName}" is complete! Pay the token amount to confirm.`,
      data: { type: 'group_update', route: `/group/${groupId}`, groupId },
    });
  }

  await batch.commit();

  // Notify buyers
  await Promise.allSettled(buyerNotifications.map((n) => notifyUser(n.userId, n)));

  // Notify supplier
  await notifyUser(after.supplierId, {
    title: '🎉 Group Order Completed!',
    body: `A group for "${after.productName}" has completed with ${after.totalQuantity} units from ${after.members?.length ?? 0} buyers.`,
    data: { type: 'group_update', route: `/supplier`, groupId },
  });

  console.log(`Orders created for completed group ${groupId}.`);
});

// ═════════════════════════════════════════════════════════════════════════════
// 3. TRIGGER — Discount approval requested → notify supplier
// ═════════════════════════════════════════════════════════════════════════════
exports.onDiscountApprovalRequested = onDocumentUpdated('groups/{groupId}', async (event) => {
  const before = event.data.before.data();
  const after  = event.data.after.data();
  const groupId = event.params.groupId;

  if (before.status === after.status) return;
  if (after.status !== 'pending_approval') return;

  await notifyUser(after.supplierId, {
    title: '📋 Discount Approval Needed',
    body: `${after.creatorBusinessName} is requesting a bulk discount for "${after.productName}" (${after.totalQuantity} units, ${after.members?.length ?? 0} buyers).`,
    data: { type: 'group_update', route: `/supplier/approvals`, groupId },
  });

  // Also save a Firestore notification for in-app display
  await saveNotification(after.supplierId, {
    title: '📋 Discount Approval Needed',
    body: `${after.creatorBusinessName} requests a discount for "${after.productName}".`,
    type: 'group_update',
    route: `/supplier/approvals`,
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 4. TRIGGER — Discount approved/rejected → notify group creator
// ═════════════════════════════════════════════════════════════════════════════
exports.onDiscountDecision = onDocumentUpdated('groups/{groupId}', async (event) => {
  const before = event.data.before.data();
  const after  = event.data.after.data();
  const groupId = event.params.groupId;

  // Only fire when discountApproved field changes
  if (before.discountApproved === after.discountApproved) return;
  if (before.status !== 'pending_approval') return;

  const approved = after.discountApproved === true;
  const note = after.discountApprovalNote ?? '';

  const title = approved ? '✅ Discount Approved!' : '❌ Discount Rejected';
  const body  = approved
    ? `${after.supplierName} approved the discount for "${after.productName}". Invite more buyers!`
    : `${after.supplierName} rejected the discount request for "${after.productName}". ${note}`;

  await notifyUser(after.creatorId, {
    title,
    body,
    data: { type: 'group_update', route: `/group/${groupId}`, groupId },
  });

  await saveNotification(after.creatorId, { title, body, type: 'group_update', route: `/group/${groupId}` });

  // Notify all other members too
  for (const member of after.members ?? []) {
    if (member.userId === after.creatorId) continue;
    await notifyUser(member.userId, {
      title,
      body,
      data: { type: 'group_update', route: `/group/${groupId}`, groupId },
    });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// 5. TRIGGER — Order status changed → notify buyer + save notification
// ═════════════════════════════════════════════════════════════════════════════
exports.onOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before  = event.data.before.data();
  const after   = event.data.after.data();
  const orderId = event.params.orderId;

  if (before.status === after.status) return;

  const messages = {
    confirmed:  `Your order for "${after.productName}" has been confirmed by ${after.supplierName}.`,
    processing: `Your order for "${after.productName}" is being processed.`,
    shipped:    `Your order for "${after.productName}" has been shipped! Delivery expected soon.`,
    delivered:  `Your order for "${after.productName}" has been delivered. Thank you!`,
    cancelled:  `Your order for "${after.productName}" has been cancelled.`,
  };

  const body = messages[after.status];
  if (!body) return;

  const title = '📦 Order Update';

  await notifyUser(after.buyerId, {
    title,
    body,
    data: { type: 'order', route: `/order/${orderId}`, orderId },
  });

  await saveNotification(after.buyerId, { title, body, type: 'order', route: `/order/${orderId}` });
});

// ═════════════════════════════════════════════════════════════════════════════
// 6. TRIGGER — Payment proof uploaded → notify supplier
// ═════════════════════════════════════════════════════════════════════════════
exports.onPaymentProofUploaded = onDocumentCreated('payments/{paymentId}', async (event) => {
  const payment = event.data.data();

  // Look up the group to find the supplier
  const groupDoc = await db.collection('groups').doc(payment.groupId).get();
  if (!groupDoc.exists) return;

  const group = groupDoc.data();
  const paymentType = payment.paymentType === 'token' ? 'Token' : 'Final';

  await notifyUser(group.supplierId, {
    title: `💰 ${paymentType} Payment Proof Received`,
    body: `${payment.businessName} has uploaded a ${paymentType.toLowerCase()} payment proof for "${group.productName}".`,
    data: { type: 'payment', route: `/supplier/order/${payment.groupId}`, groupId: payment.groupId },
  });

  await saveNotification(group.supplierId, {
    title: `💰 ${paymentType} Payment Proof`,
    body: `${payment.businessName} uploaded proof for "${group.productName}".`,
    type: 'payment',
    route: `/supplier`,
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 7. TRIGGER — New chat message → notify group members + supplier
// ═════════════════════════════════════════════════════════════════════════════
exports.onNewChatMessage = onDocumentCreated(
  'chats/{groupId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const groupId = event.params.groupId;

    if (message.type === 'system') return;

    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return;

    const group = groupDoc.data();
    const bodyText = message.type === 'text'
      ? (message.text ?? '').substring(0, 100)
      : `Sent a ${message.type}`;

    // Notify all members except sender
    const recipients = (group.members ?? []).filter((m) => m.userId !== message.senderId);

    // Also notify supplier if they're not the sender
    const notifySupplier = group.supplierId && group.supplierId !== message.senderId;

    const tasks = recipients.map((m) =>
      notifyUser(m.userId, {
        title: `💬 ${message.senderName}`,
        body: bodyText,
        data: { type: 'chat', route: `/group-chat/${groupId}`, groupId },
      })
    );

    if (notifySupplier) {
      tasks.push(
        notifyUser(group.supplierId, {
          title: `💬 ${message.senderName} (${group.productName})`,
          body: bodyText,
          data: { type: 'chat', route: `/group-chat/${groupId}`, groupId },
        })
      );
    }

    await Promise.allSettled(tasks);
  }
);

// ═════════════════════════════════════════════════════════════════════════════
// 8. TRIGGER — New member joins group → notify group creator + supplier
// ═════════════════════════════════════════════════════════════════════════════
exports.onMemberJoined = onDocumentUpdated('groups/{groupId}', async (event) => {
  const before  = event.data.before.data();
  const after   = event.data.after.data();
  const groupId = event.params.groupId;

  const prevCount = (before.members ?? []).length;
  const newCount  = (after.members  ?? []).length;

  if (newCount <= prevCount) return; // No new member

  const newMember = after.members[after.members.length - 1];

  // Notify group creator (if not the new member)
  if (after.creatorId !== newMember.userId) {
    await notifyUser(after.creatorId, {
      title: '👥 New Member Joined!',
      body: `${newMember.businessName} joined your group for "${after.productName}" with ${newMember.quantity} units.`,
      data: { type: 'group_update', route: `/group/${groupId}`, groupId },
    });
  }

  // Notify supplier for supplier-target groups
  if (after.mode === 'supplier_target' && after.supplierId !== newMember.userId) {
    await notifyUser(after.supplierId, {
      title: '👥 New Buyer Joined',
      body: `${newMember.businessName} joined the group for "${after.productName}". Total: ${after.totalQuantity} units.`,
      data: { type: 'group_update', route: `/supplier`, groupId },
    });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// 9. SCHEDULED — Payment reminders daily at 9 AM IST (3:30 UTC)
// ═════════════════════════════════════════════════════════════════════════════
exports.paymentReminders = onSchedule('30 3 * * *', async () => {
  // Find completed groups with pending token payments
  const snapshot = await db
    .collection('groups')
    .where('status', '==', 'completed')
    .get();

  const tasks = [];

  for (const doc of snapshot.docs) {
    const group = doc.data();
    const pendingMembers = (group.members ?? []).filter(
      (m) => m.paymentStatus === 'pending'
    );

    for (const member of pendingMembers) {
      tasks.push(
        notifyUser(member.userId, {
          title: '💰 Payment Reminder',
          body: `Please pay the token amount for "${group.productName}" to confirm your order.`,
          data: { type: 'payment', route: `/payment/token/${doc.id}`, groupId: doc.id },
        })
      );
    }
  }

  await Promise.allSettled(tasks);
  console.log(`Sent ${tasks.length} payment reminder(s).`);
});

// ═════════════════════════════════════════════════════════════════════════════
// 10. SCHEDULED — Supplier order follow-up: remind supplier of unconfirmed orders
// ═════════════════════════════════════════════════════════════════════════════
exports.supplierOrderReminders = onSchedule('0 9 * * *', async () => {
  // Orders that are token_paid but still 'pending' for more than 24 hours
  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const snapshot = await db
    .collection('orders')
    .where('status', '==', 'pending')
    .where('paymentStatus', '==', 'token_paid')
    .where('createdAt', '<', Timestamp.fromDate(cutoff))
    .get();

  const tasks = [];

  for (const doc of snapshot.docs) {
    const order = doc.data();
    tasks.push(
      notifyUser(order.supplierId, {
        title: '⚠️ Order Awaiting Confirmation',
        body: `${order.buyerBusinessName}'s order for "${order.productName}" has been paid but not confirmed yet.`,
        data: { type: 'order', route: `/supplier/order/${doc.id}`, orderId: doc.id },
      })
    );
  }

  await Promise.allSettled(tasks);
  console.log(`Sent ${tasks.length} supplier order reminder(s).`);
});

// ═════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════════════════════

/**
 * Send FCM push notification to a user by their Firestore UID.
 * Silently skips if the user has no FCM token.
 */
async function notifyUser(userId, { title, body, data = {} }) {
  if (!userId) return;
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // FCM data values must all be strings
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    );

    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: stringData,
      android: {
        priority: 'high',
        notification: {
          channelId: data.type ?? 'group_updates',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1, contentAvailable: true },
        },
      },
    });
  } catch (err) {
    console.error(`notifyUser(${userId}) failed:`, err.message);
  }
}

/**
 * Save a notification document to Firestore for in-app display.
 */
async function saveNotification(userId, { title, body, type, route }) {
  if (!userId) return;
  try {
    await db.collection('notifications').add({
      userId,
      title,
      body,
      type: type ?? 'group_update',
      route: route ?? null,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error(`saveNotification(${userId}) failed:`, err.message);
  }
}

/**
 * Return the best applicable pricing tier for a given quantity.
 */
function getActiveTier(tiers, totalQuantity) {
  if (!Array.isArray(tiers) || tiers.length === 0) return null;
  const sorted = [...tiers].sort((a, b) => b.minQuantity - a.minQuantity);
  return sorted.find((t) => totalQuantity >= t.minQuantity) ?? sorted[sorted.length - 1];
}
