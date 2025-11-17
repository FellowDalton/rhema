import { db, admin } from "../config/firebase.js";
import * as notificationService from "../services/notificationService.js";

const VALID_PRAYER_TYPES = ["hidden", "visible"];
const VALID_PRAYER_ACCESS_MODIFIERS = ["private", "public"];

export const createPrayer = async (req, res) => {
  try {
    const {
      title,
      description,
      endDateTime,
      prayerAccess,
      participants,
      prayerType,
    } = req.body;

    // Use the current user's ID as the creatorId
    const creatorId = req.user.uid;

    if (!VALID_PRAYER_TYPES.includes(prayerType)) {
      return res.status(400).json({ error: "Invalid prayer type" });
    }

    if (!VALID_PRAYER_ACCESS_MODIFIERS.includes(prayerAccess)) {
      return res.status(400).json({ error: "Invalid prayer access modifier" });
    }

    const newPrayer = {
      title,
      description,
      endDateTime,
      prayerAccess,
      creatorId,
      participants: {
        users: participants?.users || [],
        groups: participants?.groups || [],
      },
      prayerType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isOpen: true,
      impressionCount: 0,
    };

    const docRef = await db.collection("prayers").add(newPrayer);

    if (endDateTime) {
      const now = new Date();
      const delay = new Date(endDateTime) - now;
      setTimeout(() => closePrayerAutomatically(docRef.id), delay);
    }

    res.status(201).json({ id: docRef.id, ...newPrayer });
  } catch (error) {
    console.error("Error creating prayer:", error);
    res.status(500).json({ error: "Failed to create prayer" });
  }
};

export const getPrayer = async (req, res) => {
  try {
    const prayerDoc = await db.collection("prayers").doc(req.params.id).get();
    if (!prayerDoc.exists) {
      return res.status(404).json({ error: "Prayer not found" });
    }
    const prayerData = prayerDoc.data();

    if (prayerData.prayerType === "hidden" && prayerData.isOpen) {
      return res.status(200).json({
        id: prayerDoc.id,
        title: prayerData.title,
        description: prayerData.description,
        prayerType: prayerData.prayerType,
        impressionCount: prayerData.impressionCount,
        isOpen: prayerData.isOpen,
      });
    }

    res.status(200).json({ id: prayerDoc.id, ...prayerData });
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve prayer" });
  }
};

export const updatePrayer = async (req, res) => {
  try {
    const { title, description, endDateTime, prayerAccess, prayerType } =
      req.body;

    if (prayerType && !VALID_PRAYER_TYPES.includes(prayerType)) {
      return res.status(400).json({ error: "Invalid prayer type" });
    }

    if (!VALID_PRAYER_ACCESS_MODIFIERS.includes(prayerAccess)) {
      return res.status(400).json({ error: "Invalid prayer access modifier" });
    }

    const updateData = {
      title,
      description,
      endDateTime,
      prayerAccess,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (prayerType) {
      updateData.prayerType = prayerType;
    }

    await db.collection("prayers").doc(req.params.id).update(updateData);
    res.status(200).json({ message: "Prayer updated successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to update prayer" });
  }
};

export const deletePrayer = async (req, res) => {
  try {
    await db.collection("prayers").doc(req.params.id).delete();
    res.status(200).json({ message: "Prayer deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete prayer" });
  }
};

export const listPrayers = async (req, res) => {
  try {
    const { type } = req.query;
    let query = db.collection("prayers");

    if (type && VALID_PRAYER_TYPES.includes(type)) {
      query = query.where("prayerType", "==", type);
    }

    const prayersSnapshot = await query.get();
    const prayers = prayersSnapshot.docs.map((doc) => {
      const data = doc.data();
      if (data.prayerType === "hidden" && data.isOpen) {
        return {
          id: doc.id,
          title: data.title,
          description: data.description,
          prayerType: data.prayerType,
          impressionCount: data.impressionCount,
          isOpen: data.isOpen,
        };
      }
      return { id: doc.id, ...data };
    });
    res.status(200).json(prayers);
  } catch (error) {
    res.status(500).json({ error: "Failed to list prayers" });
  }
};

export const closePrayer = async (req, res) => {
  try {
    const prayerId = req.params.id;
    const prayerRef = db.collection("prayers").doc(prayerId);
    const prayerDoc = await prayerRef.get();

    if (!prayerDoc.exists) {
      return res.status(404).json({ error: "Prayer not found" });
    }

    if (prayerDoc.data().creatorId !== req.user.uid) {
      return res
        .status(403)
        .json({ error: "Only the prayer creator can close the prayer" });
    }

    await prayerRef.update({
      isOpen: false,
      closedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await notificationService.notifyPrayerClosed(prayerId);

    res.status(200).json({ message: "Prayer closed successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to close prayer" });
  }
};

export const addParticipants = async (req, res) => {
  try {
    const prayerId = req.params.id;
    const { users = [], groups = [] } = req.body;
    const prayerRef = db.collection("prayers").doc(prayerId);
    const prayerDoc = await prayerRef.get();

    if (!prayerDoc.exists) {
      return res.status(404).json({ error: "Prayer not found" });
    }

    if (prayerDoc.data().creatorId !== req.user.uid) {
      return res
        .status(403)
        .json({ error: "Only the prayer creator can add participants" });
    }

    await prayerRef.update({
      "participants.users": admin.firestore.FieldValue.arrayUnion(...users),
      "participants.groups": admin.firestore.FieldValue.arrayUnion(...groups),
    });

    users.forEach((userId) =>
      notificationService.notifyUserAddedToPrayer(userId, prayerId)
    );

    res.status(200).json({ message: "Participants added successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to add participants" });
  }
};

export const removeParticipants = async (req, res) => {
  try {
    const prayerId = req.params.id;
    const { users = [], groups = [] } = req.body;
    const prayerRef = db.collection("prayers").doc(prayerId);
    const prayerDoc = await prayerRef.get();

    if (!prayerDoc.exists) {
      return res.status(404).json({ error: "Prayer not found" });
    }

    if (prayerDoc.data().creatorId !== req.user.uid) {
      return res
        .status(403)
        .json({ error: "Only the prayer creator can remove participants" });
    }

    await prayerRef.update({
      "participants.users": admin.firestore.FieldValue.arrayRemove(...users),
      "participants.groups": admin.firestore.FieldValue.arrayRemove(...groups),
    });

    users.forEach((userId) =>
      notificationService.notifyUserRemovedFromPrayer(userId, prayerId)
    );

    res.status(200).json({ message: "Participants removed successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to remove participants" });
  }
};

export const addImpression = async (req, res) => {
  try {
    const { content } = req.body;
    const prayerId = req.params.id;
    const userId = req.user.uid;

    const prayerRef = db.collection("prayers").doc(prayerId);
    const prayerDoc = await prayerRef.get();

    if (!prayerDoc.exists) {
      return res.status(404).json({ error: "Prayer not found" });
    }

    if (!prayerDoc.data().isOpen) {
      return res
        .status(400)
        .json({ error: "Prayer is closed for impressions" });
    }

    const newImpression = {
      content,
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.runTransaction(async (transaction) => {
      const impressionRef = prayerRef.collection("impressions").doc();
      transaction.set(impressionRef, newImpression);
      transaction.update(prayerRef, {
        impressionCount: admin.firestore.FieldValue.increment(1),
      });
    });

    if (prayerDoc.data().prayerType === "visible") {
      notificationService.notifyNewImpression(prayerId, userId);
    }

    res.status(201).json({ message: "Impression added successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to add impression" });
  }
};

async function closePrayerAutomatically(prayerId) {
  try {
    const prayerRef = db.collection("prayers").doc(prayerId);
    const prayerDoc = await prayerRef.get();
    const prayerData = prayerDoc.data();

    await prayerRef.update({
      isOpen: false,
      closedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    notificationService.notifyPrayerClosed(prayerId);

    if (prayerData.prayerType === "hidden") {
      const impressionsSnapshot = await prayerRef
        .collection("impressions")
        .get();
      const impressions = impressionsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      notificationService.notifyHiddenImpressionsRevealed(
        prayerId,
        impressions
      );
    }
  } catch (error) {
    console.error(`Failed to automatically close prayer ${prayerId}:`, error);
  }
}
