import UserModel from "../models/User.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import crypto from "crypto";
import sendVerificationEmail from "../utils/sendEmail.js";
import { v4 as uuidv4 } from "uuid";
class UserServices {
  static async registerUser(userData) {
    try {
      const rawToken = uuidv4();
      const hashedToken = crypto
        .createHash("sha256")
        .update(rawToken)
        .digest("hex");

      const newUser = new UserModel({
        userId: uuidv4(),
        displayName: userData.displayName,
        gender: userData.gender,
        email: userData.email,
        password: userData.password,
        country: userData.country,
        city: userData.city || "", // optional
        role: (userData.role || "user").toLowerCase(),
        language: userData.language,
        createdAt: new Date(),
        verificationToken: hashedToken,
        verificationTokenExpires: new Date(Date.now() + 3600000),
        // Add ai_session_id if provided
        ai_session_id: userData.ai_session_id || undefined,

        volunteerProfile:
          userData.role === "volunteer_pending"
            ? {
                certificate: {
                  title: userData.certification_title,
                  institution: userData.certification_institution,
                  url: userData.certification_url,
                  uploadedAt: new Date(),
                },
                languages: userData.spoken_languages || [],
                bio: userData.bio || "",
              }
            : undefined,
      });

      await newUser.save();
      sendVerificationEmail(newUser.email, rawToken);
      return newUser;
    } catch (err) {
      throw err;
    }
  }

  static async checkUser(email) {
    try {
      return await UserModel.findOne({ email });
    } catch (error) {
      throw error;
    }
  }

  static async checkUserById(userId) {
    try {
      return await UserModel.findOne({ userId });
    } catch (error) {
      throw error;
    }
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async generateAccessToken(tokenData, JWTSecret_Key, JWT_EXPIRE) {
    return jwt.sign(tokenData, JWTSecret_Key, { expiresIn: JWT_EXPIRE });
  }

  static async updateUserById(userId, updateData) {
    try {
      const updatedUser = await UserModel.findOneAndUpdate(
        { userId },
        { $set: updateData },
        { new: true, runValidators: true }
      );

      if (!updatedUser) {
        throw new Error("User not found");
      }

      return updatedUser;
    } catch (err) {
      throw err;
    }
  }

  static async verifyEmail(token) {
    if (!token) throw new Error("Token is required");

    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

    const user = await UserModel.findOne({
      verificationToken: hashedToken,
      verificationTokenExpires: { $gt: Date.now() },
    });

    if (!user) {
      const error = new Error("Invalid or expired verification token");
      error.statusCode = 400;
      throw error;
    }

    if (user.isEmailVerified) {
      const error = new Error("Email already verified");
      error.statusCode = 400;
      throw error;
    }

    user.isEmailVerified = true;
    user.verificationToken = undefined;
    user.verificationTokenExpires = undefined;

    await user.save();

    return user;
  }
  static async updateOneSignalId(userId, onesignalId) {
    try {
      const updatedUser = await UserModel.findOneAndUpdate(
        { userId },
        { $set: { onesignalId } },
        { new: true, runValidators: true }
      );

      if (!updatedUser) {
        throw new Error("User not found");
      }

      return updatedUser;
    } catch (err) {
      throw err;
    }
  }

  // Notification-related methods
  static async getNotifications(userId) {
    try {
      const user = await UserModel.findOne({ userId });
      if (!user) {
        throw new Error("User not found");
      }
      return user.notifications || [];
    } catch (err) {
      throw err;
    }
  }

  static async markNotificationAsRead(userId, notificationId) {
    try {
      const result = await UserModel.updateOne(
        { userId, "notifications.id": notificationId },
        { $set: { "notifications.$.read": true } }
      );

      if (result.modifiedCount === 0) {
        throw new Error("Notification not found");
      }

      return result;
    } catch (err) {
      throw err;
    }
  }

  static async markAllNotificationsAsRead(userId) {
    try {
      const result = await UserModel.updateOne(
        { userId },
        { $set: { "notifications.$[].read": true } }
      );

      return result;
    } catch (err) {
      throw err;
    }
  }

  static async deleteAllNotifications(userId) {
    try {
      const result = await UserModel.updateOne(
        { userId },
        { $set: { notifications: [] } }
      );

      return result;
    } catch (err) {
      throw err;
    }
  }

  static async addNotification(userId, notification) {
    try {
      const result = await UserModel.updateOne(
        { userId },
        { $push: { notifications: notification } }
      );

      return result;
    } catch (err) {
      throw err;
    }
  }

  static async findVolunteers() {
    try {
      return await UserModel.find({ role: "volunteer" });
    } catch (err) {
      throw err;
    }
  }

  static async findInactiveVolunteers(cutoffDate) {
    try {
      return await UserModel.find({
        role: "volunteer",
        // Add logic to find inactive volunteers based on your data structure
        // For example: lastAnswerDate: { $lt: cutoffDate }
      });
    } catch (err) {
      throw err;
    }
  }

  static async getUserById(userId) {
    try {
      return await UserModel.findOne({ userId });
    } catch (err) {
      throw err;
    }
  }

  static async hashPassword(password) {
    return await bcrypt.hash(password, 10);
  }

  static async getUserByEmail(email) {
    try {
      return await UserModel.findOne({ email });
    } catch (err) {
      throw err;
    }
  }
  static async deleteUserById(userId) {
    try {
      const result = await UserModel.deleteOne({ userId });
      if (result.deletedCount === 0) {
        throw new Error("User not found");
      }
      return result;
    } catch (err) {
      throw err;
    }
  }
}

export default UserServices;
