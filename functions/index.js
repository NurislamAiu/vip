"use strict";

/**
 * Push notifications for VIP Client Manager.
 *
 * Client apps subscribe to the "staff" FCM topic (see NotificationService).
 * These functions publish to that topic:
 *   - onClientCreated  → "New client"
 *   - onClientUpdated  → "Client updated"
 *   - sendReminders    → scheduled sweep that fires:
 *        · ~2 hours before arrival
 *        · ~30 minutes before a doctor appointment
 *        · on the morning of a departure
 *
 * Reminders are de-duplicated by writing marker flags back onto the client
 * document, so a client is never reminded twice for the same event.
 */

const { onDocumentCreated, onDocumentUpdated } =
  require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const TOPIC = "staff";
const messaging = admin.messaging();
const db = admin.firestore();

function notify(title, body, data = {}) {
  return messaging.send({
    topic: TOPIC,
    notification: { title, body },
    data,
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
}

exports.onClientCreated = onDocumentCreated("clients/{id}", (event) => {
  const client = event.data.data();
  if (!client) return null;
  return notify(
    "Новый клиент",
    `Добавлен клиент ${client.name || ""} (№${client.clientNumber || "—"}).`,
    { type: "client_created", clientId: event.params.id },
  );
});

exports.onClientUpdated = onDocumentUpdated("clients/{id}", (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return null;

  // Ignore updates that only touched our own reminder markers.
  const ignored = new Set([
    "updatedAt",
    "remindedArrival",
    "remindedAppointment",
    "remindedDeparture",
  ]);
  const changed = Object.keys(after).some(
    (k) => !ignored.has(k) && JSON.stringify(after[k]) !== JSON.stringify(before[k]),
  );
  if (!changed) return null;

  return notify(
    "Клиент обновлён",
    `Обновлён клиент ${after.name || ""} (№${after.clientNumber || "—"}).`,
    { type: "client_updated", clientId: event.params.id },
  );
});

/** Combines a Firestore date Timestamp with an "HH:mm" string into a Date. */
function combine(dateTs, timeStr) {
  if (!dateTs) return null;
  const d = dateTs.toDate();
  if (typeof timeStr === "string" && /^\d{1,2}:\d{2}$/.test(timeStr)) {
    const [h, m] = timeStr.split(":").map(Number);
    d.setHours(h, m, 0, 0);
  }
  return d;
}

function isSameDay(a, b) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

// Runs every 15 minutes.
exports.sendReminders = onSchedule("every 15 minutes", async () => {
  const now = new Date();
  const snap = await db.collection("clients").get();

  const jobs = [];
  for (const doc of snap.docs) {
    const c = doc.data();
    const patch = {};

    // ~2 hours before arrival (fire once within the 2h–1h45m window).
    const arrival = combine(c.arrivalDate, c.arrivalTime);
    if (arrival && !c.remindedArrival) {
      const mins = (arrival - now) / 60000;
      if (mins > 105 && mins <= 120) {
        jobs.push(notify("Прибытие через ~2 часа",
          `${c.name} прибывает в ${c.arrivalTime || "ближайшее время"}.`,
          { type: "arrival_soon", clientId: doc.id }));
        patch.remindedArrival = true;
      }
    }

    // ~30 minutes before the appointment.
    const appt = combine(c.doctorAppointmentDate, c.doctorAppointmentTime);
    if (appt && !c.remindedAppointment) {
      const mins = (appt - now) / 60000;
      if (mins > 15 && mins <= 30) {
        jobs.push(notify("Приём через ~30 минут",
          `${c.name} — приём у ${c.doctorName || "врача"} в ${c.doctorAppointmentTime || "ближайшее время"}.`,
          { type: "appointment_soon", clientId: doc.id }));
        patch.remindedAppointment = true;
      }
    }

    // Morning-of departure notice.
    if (c.departureDate && !c.remindedDeparture) {
      const dep = c.departureDate.toDate();
      if (isSameDay(dep, now)) {
        jobs.push(notify("Вылет сегодня",
          `${c.name} улетает сегодня${c.departureTime ? " в " + c.departureTime : ""}.`,
          { type: "departure_today", clientId: doc.id }));
        patch.remindedDeparture = true;
      }
    }

    if (Object.keys(patch).length) {
      jobs.push(doc.ref.set(patch, { merge: true }));
    }
  }

  await Promise.all(jobs);
});
