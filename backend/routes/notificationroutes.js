import express from "express";
const router = express.Router();
import {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteAllNotifications,
  sendTestNotification,
} from "../controller/notificationcontroller.js";
import authMiddleware from "../services/authMiddleware.js";

// Notification routes
router.get("/", authMiddleware, getNotifications);
router.put("/:notificationId/read", authMiddleware, markNotificationAsRead);
router.put("/mark-all-read", authMiddleware, markAllNotificationsAsRead);
router.delete("/", authMiddleware, deleteAllNotifications);
router.post("/test", authMiddleware, sendTestNotification);

export default router;
