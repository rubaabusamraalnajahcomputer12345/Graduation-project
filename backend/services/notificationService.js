import axios from "axios";
import UserServices from "./userserviceslog&registeration.js";
import { v4 as uuidv4 } from "uuid";

// OneSignal configuration
const ONESIGNAL_APP_ID = "b068d3f0-99d0-487c-a233-fde4b91a5b8c";
const ONESIGNAL_REST_API_KEY =
  "Basic os_v2_app_wbunh4ez2behzirt7xslsgs3rry7mziwff4u7ymcsghcbu3zus6qvyrc2d622aorr5kohywje4s66y6fog7zsujowu4gkiwinzb6zga";

/**
 * General function to send push notification and save to database
 * @param {Object} options - Notification options
 * @param {string} options.userId - Target user's ID
 * @param {string} options.type - Notification type (welcome, question_answered, answer_upvoted, etc.)
 * @param {string} options.title - Push notification title
 * @param {string} options.message - Push notification message
 * @param {Object} options.data - Additional data for navigation (optional)
 * @param {boolean} options.saveToDatabase - Whether to save to database (default: true)
 * @returns {Promise<Object>} - Result object
 */
async function sendNotification(options) {
  const {
    userId,
    type,
    title,
    message,
    data = {},
    saveToDatabase = true,
  } = options;

  try {
    // Validate required parameters
    if (!userId || !type || !title || !message) {
      throw new Error(
        "Missing required parameters: userId, type, title, message"
      );
    }

    // Get user to check if they have OneSignal ID
    const user = await UserServices.checkUserById(userId);
    if (!user) {
      throw new Error(`User not found with ID: ${userId}`);
    }

    const result = {
      pushSent: false,
      databaseSaved: false,
      errors: [],
    };

    // 1. Send OneSignal push notification
    if (user.onesignalId) {
      try {
        const pushResponse = await sendOneSignalPush({
          playerId: user.onesignalId,
          title: title,
          message: message,
          data: {
            type: type,
            ...data,
          },
        });

        if (pushResponse.success) {
          result.pushSent = true;
          console.log(`Push notification sent successfully to user ${userId}`);
        } else {
          result.errors.push(`Push notification failed: ${pushResponse.error}`);
        }
      } catch (pushError) {
        result.errors.push(`Push notification error: ${pushError.message}`);
        console.error("Push notification error:", pushError);
      }
    } else {
      result.errors.push("User has no OneSignal ID");
    }

    // 2. Save to database
    if (saveToDatabase) {
      try {
        const notificationData = {
          id: uuidv4(),
          type: type,
          title: title,
          message: message,
          data: data,
          read: false,
          createdAt: new Date().toISOString(),
        };

        await UserServices.addNotification(userId, notificationData);
        result.databaseSaved = true;
        console.log(`Notification saved to database for user ${userId}`);
      } catch (dbError) {
        result.errors.push(`Database error: ${dbError.message}`);
        console.error("Database error:", dbError);
      }
    }

    return result;
  } catch (error) {
    console.error("sendNotification error:", error);
    return {
      pushSent: false,
      databaseSaved: false,
      errors: [error.message],
    };
  }
}

async function sendOneSignalPush(options) {
  const { playerId, title, message, data } = options;

  try {
    // For user_match notifications, add custom action to trigger popup
    const isUserMatch = data?.type === "user_match";
    const customAction = isUserMatch ? "show_connection_popup" : undefined;

    const response = await axios.post(
      `https://onesignal.com/api/v1/notifications`,
      {
        app_id: ONESIGNAL_APP_ID,
        include_player_ids: [playerId],
        headings: { en: title },
        contents: { en: message },
        data: {
          ...data,
          action: customAction, // Custom action for frontend to handle
        },
        priority: 10,
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
        },
      }
    );

    if (response.status === 200) {
      return { success: true, data: response.data };
    } else {
      return { success: false, error: `HTTP ${response.status}` };
    }
  } catch (error) {
    console.error(
      "OneSignal API error:",
      error.response?.data || error.message
    );
    return {
      success: false,
      error: error.response?.data?.errors?.[0] || error.message,
    };
  }
}

/**
 * Send notification to multiple users
 * @param {Array} userIds - Array of user IDs
 * @param {Object} options - Notification options (same as sendNotification)
 * @returns {Promise<Array>} - Array of results for each user
 */
async function sendNotificationToMultiple(userIds, options) {
  const results = [];

  for (const userId of userIds) {
    const result = await sendNotification({
      ...options,
      userId: userId,
    });
    results.push({ userId, ...result });
  }

  return results;
}

/**
 * Send notification to all volunteers
 * @param {Object} options - Notification options (same as sendNotification)
 * @returns {Promise<Array>} - Array of results for each volunteer
 */
async function sendNotificationToAllVolunteers(options) {
  try {
    const volunteers = await UserServices.findVolunteers();
    const volunteerIds = volunteers.map((v) => v.userId);

    return await sendNotificationToMultiple(volunteerIds, options);
  } catch (error) {
    console.error("Error sending to all volunteers:", error);
    return [];
  }
}

/**
 * Send notification to inactive volunteers (haven't answered in X days)
 * @param {number} daysInactive - Number of days to consider inactive
 * @param {Object} options - Notification options (same as sendNotification)
 * @returns {Promise<Array>} - Array of results for each inactive volunteer
 */
async function sendNotificationToInactiveVolunteers(daysInactive, options) {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysInactive);

    // Find volunteers who haven't answered questions recently
    // This is a simplified query - you might need to adjust based on your data structure
    const inactiveVolunteers = await UserServices.findInactiveVolunteers(
      cutoffDate
    );

    const volunteerIds = inactiveVolunteers.map((v) => v.userId);

    return await sendNotificationToMultiple(volunteerIds, options);
  } catch (error) {
    console.error("Error sending to inactive volunteers:", error);
    return [];
  }
}

/**
 * Get notification statistics for a user
 * @param {string} userId - User ID
 * @returns {Promise<Object>} - Notification statistics
 */
async function getNotificationStats(userId) {
  try {
    const notifications = await UserServices.getNotifications(userId);
    const total = notifications.length;
    const unread = notifications.filter((n) => !n.read).length;
    const read = total - unread;

    return {
      total,
      unread,
      read,
      lastNotification: notifications.length > 0 ? notifications[0] : null,
    };
  } catch (error) {
    console.error("Error getting notification stats:", error);
    return { total: 0, unread: 0, read: 0, lastNotification: null };
  }
}

export {
  sendNotification,
  sendNotificationToMultiple,
  sendNotificationToAllVolunteers,
  sendNotificationToInactiveVolunteers,
  getNotificationStats,
};
