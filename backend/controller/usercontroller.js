import UserServices from "../services/userserviceslog&registeration.js";
import sendVerificationEmail from "../utils/sendEmail.js";
import admin from "firebase-admin";
import { sendNotification } from "../services/notificationService.js";
import { sendMissedNotifications } from "./notificationcontroller.js";
import sendResetPasswordEmail from "../utils/resetPassword.js";

export async function register(req, res, next) {
  try {
    console.log("--- req body ---", req.body);

    const {
      displayName,
      email,
      password,
      gender,
      country,
      role,
      language,
      certification_title,
      certification_institution,
      certification_url,
      bio,
      spoken_languages,
    } = req.body;

    const NewuserData = {
      displayName,
      email,
      password,
      gender,
      country,
      role,
      language,
      certification_title,
      certification_institution,
      certification_url,
      bio,
      spoken_languages,
    };

    const createdUser = await UserServices.registerUser(NewuserData);
    await sendVerificationEmail(email, createdUser.verificationToken);
    const userToReturn = createdUser.toObject();
    delete userToReturn.password;

    res.status(201).json({
      status: true,
      success: "User registered successfully",
      user: userToReturn,
    });
  } catch (err) {
    console.log("---> err -->", err);
    next(err);
  }
}

export async function login(req, res, next) {
  const { role, email, password } = req.body;
  let user = await UserServices.checkUser(email);

  if (!user) {
    return res
      .status(404)
      .json({ status: false, message: "User does not exist" });
  }
  const isPasswordValid = await UserServices.verifyPassword(
    password,
    user.password
  );
  if (!isPasswordValid) {
    return res.status(401).json({ status: false, message: "Invalid password" });
  }
  // Allow login if user role is either 'volunteer_pending' or 'certified_volunteer' and requested role is either one
  if (
    (role === "volunteer_pending" || role === "certified_volunteer") &&
    (user.role === "volunteer_pending" || user.role === "certified_volunteer")
  ) {
    // continue, treat as authorized
  } else if (user.role !== role) {
    return res
      .status(403)
      .json({ status: false, message: "Access denied: role mismatch" });
  }

  // Creating Token
  let tokenData;
  tokenData = { _id: user.userId, email: user.email, role: user.role };

  const token = await UserServices.generateAccessToken(
    tokenData,
    "secret",
    "1h"
  );
  res.status(200).json({
    status: true,
    success: "sendData",
    token: token,
    user: {
      id: user.userId,
      displayName: user.displayName,
      email: user.email,
      role: user.role,
      gender: user.gender,
      country: user.country,
      language: user.language,
      savedQuestions: user.savedQuestions,
      savedLessons: user.savedLessons,
      volunteerProfile: user.volunteerProfile,
      isEmailVerified: user.isEmailVerified,
      onesignalId: user.onesignalId,
      savedStories: user.savedStories,
      notifications: user.notifications,
      lessonsProgress: user.lessonsProgress,
      ...(user.city && { city: user.city }),
      ai_session_id: user.ai_session_id,
    },
  });

  /*  // Send welcome notification and check for missed notifications
  try {
    // Welcome notification using new service
    const welcomeResult = await sendNotification({
      userId: user.userId,
      type: "welcome",
      title: "Welcome to Hidaya! 🎉",
      message: `Hello ${user.displayName}! 😊 Welcome back to Hidaya! We're so happy to see you again,We’ve prepared some questions based on your background – ready to explore? and let us know if you need anything!`,
      data: {
        userId: user.userId,
      },
    });

    console.log("Welcome notification result:", welcomeResult);

    // Check for missed notifications for volunteers
    if (
      user.role === "certified_volunteer" ||
      user.role === "volunteer_pending"
    ) {
      await sendMissedNotifications(user);
    }
  } catch (notificationError) {
    console.log("Failed to send welcome notification:", notificationError);
    // Don't fail the login if notification fails
  } */
}
export async function updateCity(req, res, next) {
  try {
    const userId = req.userId; // coming from token middleware
    const { city } = req.body;

    if (!city) {
      return res
        .status(400)
        .json({ status: false, message: "City is required in request body" });
    }

    const updateData = { city };
    const updatedUser = await UserServices.updateUserById(userId, updateData);

    const userToReturn = updatedUser.toObject
      ? updatedUser.toObject()
      : updatedUser;
    delete userToReturn.password;

    return res.status(200).json({
      status: true,
      success: "City updated successfully",
      user: userToReturn,
    });
  } catch (err) {
    console.log("---> err in updateCity -->", err);
    next(err);
  }
}

export async function updateprofile(req, res, next) {
  try {
    const userId = req.userId; // coming from token middleware
    const {
      displayName,
      gender,
      email,
      country,
      city,
      language,
      role,
      savedQuestions,
      savedLessons,
      bio,
      spoken_languages,
      certification_title,
      certification_institution,
      certification_url,
    } = req.body;

    if (!role) {
      return res
        .status(400)
        .json({ status: false, message: "Role is required in request body" });
    }

    // Base data for all users
    let updateData = {
      displayName,
      gender,
      email,
      country,
      city,
      language,
      role,
    };
    if (role === "user") {
      updateData.savedQuestions = savedQuestions || [];
      updateData.savedLessons = savedLessons || [];
    }

    if (role === "certified_volunteer" || role === "volunteer_pending") {
      updateData.volunteerProfile = {
        bio: bio || "",
        languages: spoken_languages || [],
        certificate: {
          title: certification_title || "",
          institution: certification_institution || "",
          url: certification_url || "",
          uploadedAt: new Date(),
        },
      };
    }
    console.log("UPDATE DATA", updateData);

    const updatedUser = await UserServices.updateUserById(userId, updateData);

    const userToReturn = updatedUser.toObject
      ? updatedUser.toObject()
      : updatedUser;
    delete userToReturn.password;

    // Send real-time notification for profile update
    try {
      await sendNotification({
        userId: userId,
        type: "profile_updated",
        title: "✅ Profile Updated",
        message: "Your profile was updated successfully.",
        data: {
          action: "profile_update",
          updatedAt: new Date().toISOString(),
          userId: userId,
        },
        saveToDatabase: true,
      });
    } catch (notificationError) {
      console.log(
        "Failed to send profile update notification:",
        notificationError
      );
      // Don't fail the profile update if notification fails
    }

    return res.status(200).json({
      status: true,
      success: "Profile updated successfully",
      user: userToReturn,
    });
  } catch (err) {
    console.log("---> err in updateprofile -->", err);
    next(err);
  }
}

export async function verifyEmail(req, res, next) {
  try {
    const { token } = req.params;
    const user = await UserServices.verifyEmail(token);
    res.send(`
      <html>
        <head>
          <title>Email Verified</title>
          <style>
            body {
              background-color: #f5f5f5;
              font-family: sans-serif;
              text-align: center;
              padding-top: 100px;
            }
            .checkmark-circle {
              width: 100px;
              height: 100px;
              border-radius: 50%;
              background: white;
              border: 5px solid #4CAF50;
              display: inline-flex;
              align-items: center;
              justify-content: center;
              margin-bottom: 20px;
            }
            .checkmark {
              font-size: 48px;
              color: #4CAF50;
            }
            .message {
              font-size: 20px;
              color: #333;
            }
          </style>
        </head>
        <body>
          <div class="checkmark-circle">
            <div class="checkmark">✔</div>
          </div>
          <h2 class="message">Email verified successfully</h2>
          <p class="message">You can now login to the app.</p>
        </body>
      </html>
    `);
    res
      .status(200)
      .json({ status: true, message: "Email verified successfully" });
  } catch (err) {
    console.log("---> err in verifyEmail -->", err);
    next(err);
  }
}

export async function changepassword(req, res, next) {
  try {
    console.log("--- req body ---", req.body);
    const { currentPassword, newPassword } = req.body;
    const userId = req.userId; //coming from token middleware
    console.log("--- userId ---", userId);
    const user = await UserServices.getUserById(userId);
    const isPasswordValid = await UserServices.verifyPassword(
      currentPassword,
      user.password
    );
    if (!isPasswordValid) {
      return res
        .status(401)
        .json({ status: false, message: "Invalid old password" });
    }
    if (currentPassword === newPassword) {
      return res.status(400).json({
        status: false,
        message: "New password cannot be the same as old password",
      });
    }
    const hashedNewPassword = await UserServices.hashPassword(newPassword);
    await UserServices.updateUserById(userId, { password: hashedNewPassword });

    // Send real-time notification for password change
    try {
      await sendNotification({
        userId: userId,
        type: "password_changed",
        title: "🔐 Password Changed",
        message: "Password changed successfully.",
        data: {
          action: "password_change",
          changedAt: new Date().toISOString(),
          userId: userId,
        },
        saveToDatabase: true,
      });
    } catch (notificationError) {
      console.log(
        "Failed to send password change notification:",
        notificationError
      );
      // Don't fail the password change if notification fails
    }

    res
      .status(200)
      .json({ status: true, message: "Password changed successfully" });
  } catch (err) {
    console.log("---> err in changepassword -->", err);
  }
}
// Update OneSignal ID for push notifications
export async function updateOneSignalId(req, res, next) {
  try {
    const userId = req.userId;
    const { onesignalId } = req.body;

    if (!onesignalId) {
      return res.status(400).json({
        status: false,
        message: "OneSignal ID is required",
      });
    }

    const updatedUser = await UserServices.updateOneSignalId(
      userId,
      onesignalId
    );

    res.status(200).json({
      status: true,
      success: "OneSignal ID updated successfully",
      user: {
        id: updatedUser.userId,
        onesignalId: updatedUser.onesignalId,
      },
    });
  } catch (err) {
    console.log("---> err in updateOneSignalId -->", err);
    next(err);
  }
}

export async function forgotpassword(req, res, next) {
  try {
    const { email } = req.body;
    console.log("--- email ---", email);
    const user = await UserServices.getUserByEmail(email);
    if (!user) {
      return res.status(404).json({ status: false, message: "User not found" });
    }
    console.log("--- user ---", user);
    const tokenData = { _id: user.userId, email: user.email, role: user.role };
    const token = await UserServices.generateAccessToken(
      tokenData,
      "secret",
      "1h"
    );
    await sendResetPasswordEmail(email, token);
    res.status(200).json({
      status: true,
      message: "Password reset email sent",
      token: token,
    });
  } catch (err) {
    console.log("---> err in forgotpassword -->", err);
    next(err);
  }
}
// Change password
export async function changePassword(req, res, next) {
  try {
    const userId = req.userId;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        status: false,
        message: "Current password and new password are required",
      });
    }

    // Get user to verify current password
    const user = await UserServices.checkUserById(userId);
    if (!user) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await UserServices.verifyPassword(
      currentPassword,
      user.password
    );

    if (!isCurrentPasswordValid) {
      return res.status(401).json({
        status: false,
        message: "Current password is incorrect",
      });
    }

    // Update password
    const updatedUser = await UserServices.updateUserById(userId, {
      password: newPassword,
    });

    // Send real-time notification for password change
    try {
      await sendNotification({
        userId: userId,
        type: "password_changed",
        title: "🔐 Password Changed",
        message: "Password changed successfully.",
        data: {
          action: "password_change",
          changedAt: new Date().toISOString(),
          userId: userId,
        },
        saveToDatabase: true,
      });
    } catch (notificationError) {
      console.log(
        "Failed to send password change notification:",
        notificationError
      );
      // Don't fail the password change if notification fails
    }

    res.status(200).json({
      status: true,
      success: "Password changed successfully",
    });
  } catch (err) {
    console.log("---> err in changePassword -->", err);
    next(err);
  }
}

// Delete account
export async function deleteAccount(req, res, next) {
  try {
    const userId = req.userId;

    // Get user to verify password
    const user = await UserServices.checkUserById(userId);
    if (!user) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    // Send notification before deleting account
    try {
      await sendNotification({
        userId: userId,
        type: "account_deleted",
        title: "🗑️ Account Deleted",
        message:
          "Your account has been deleted. It's okay to take a breath and empty your mind. Take your time, we are waiting for you. May Allah lead you to the right path.",
        data: {
          action: "account_deletion",
          deletedAt: new Date().toISOString(),
          userId: userId,
        },
        saveToDatabase: true,
      });
    } catch (notificationError) {
      console.log(
        "Failed to send account deletion notification:",
        notificationError
      );
      // Continue with account deletion even if notification fails
    }

    // Delete user account
    await UserServices.deleteUserById(userId);

    res.status(200).json({
      status: true,
      success: "Account deleted successfully",
    });
  } catch (err) {
    console.log("---> err in deleteAccount -->", err);
    next(err);
  }
}

export async function resetpassword(req, res, next) {
  const { token } = req.params;
  try {
    res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Reset Password</title>
          <style>
            body {
              background-color: #ffffff;
              font-family: Arial, sans-serif;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              height: 100vh;
              margin: 0;
            }
            .container {
              text-align: center;
              max-width: 400px;
              width: 100%;
            }
            .password-container {
              position: relative;
              width: 100%;
              margin-bottom: 20px;
            }
            input[type="password"], input[type="text"] {
              padding: 12px;
              width: 100%;
              font-size: 16px;
              border: 1px solid #ccc;
              border-radius: 6px;
              box-sizing: border-box;
            }
            .password-toggle {
              position: absolute;
              right: 12px;
              top: 50%;
              transform: translateY(-50%);
              background: none;
              border: none;
              cursor: pointer;
              color: #666;
              width: 20px;
              height: 20px;
              display: flex;
              align-items: center;
              justify-content: center;
            }
            .password-toggle:hover {
              color: #333;
            }
            .eye-icon {
              font-size: 18px;
              font-weight: bold;
            }
            button {
              padding: 12px 20px;
              font-size: 16px;
              background-color: #4CAF50;
              color: white;
              border: none;
              border-radius: 6px;
              cursor: pointer;
            }
            button:hover {
              background-color: #45a049;
            }
            .message {
              margin-top: 20px;
              font-size: 16px;
              color: #333;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>Reset Your Password</h2>
                         <div class="password-container">
               <input type="password" id="newPassword" placeholder="Enter new password" />
                                               <button type="button" class="password-toggle" onclick="togglePassword()">
                  <span class="eye-icon">👁️</span>
                </button>
             </div>
            <button onclick="submitPassword()">Reset Password</button>
            <div class="message" id="message"></div>
          </div>

          <script>
  const token = "${token}"; // ← خزن التوكن كقيمة ثابتة
  
  function togglePassword() {
    const passwordInput = document.getElementById("newPassword");
    const toggleButton = document.querySelector(".password-toggle");
    
    if (passwordInput.type === "password") {
      passwordInput.type = "text";
      toggleButton.innerHTML = '<span class="eye-icon">🙈</span>';
    } else {
      passwordInput.type = "password";
      toggleButton.innerHTML = '<span class="eye-icon">👁️</span>';
    }
  }
  
  async function submitPassword() {
    const newPassword = document.getElementById("newPassword").value;
    const messageEl = document.getElementById("message");

    if (!newPassword || newPassword.length < 6) {
      messageEl.textContent = "Password must be at least 6 characters.";
      return;
    }

    try {
      const response = await fetch("/reset-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + token
        },
        body: JSON.stringify({ newPassword })
      });

      const data = await response.json();

      if (data.status) {
        messageEl.textContent = "Password reset successfully. You can close this window.";
        messageEl.style.color = "green";
      } else {
        messageEl.textContent = "Something went wrong. Try again.";
        messageEl.style.color = "red";
      }
    } catch (err) {
      messageEl.textContent = "Request failed. Check your connection.";
      messageEl.style.color = "red";
    }
  }
</script>

        </body>
      </html>
    `);
  } catch (err) {
    console.log("---> err in resetpassword -->", err);
    next(err);
  }
}

export async function changeresetpassword(req, res, next) {
  try {
    console.log("--- req body ---", req.body);
    const { newPassword } = req.body;
    const userId = req.userId; //coming from token middleware
    console.log("--- userId ---", userId);
    const user = await UserServices.getUserById(userId);
    if (user.password === newPassword) {
      return res.status(400).json({
        status: false,
        message: "New password cannot be the same as old password",
      });
    }
    const hashedNewPassword = await UserServices.hashPassword(newPassword);
    await UserServices.updateUserById(userId, { password: hashedNewPassword });

    // Send real-time notification for password reset
    try {
      await sendNotification({
        userId: userId,
        type: "password_changed",
        title: "🔐 Password Changed",
        message: "Password changed successfully.",
        data: {
          action: "password_change",
          changedAt: new Date().toISOString(),
          userId: userId,
        },
        saveToDatabase: true,
      });
    } catch (notificationError) {
      console.log(
        "Failed to send password change notification:",
        notificationError
      );
      // Don't fail the password change if notification fails
    }

    res
      .status(200)
      .json({ status: true, message: "Password changed successfully" });
  } catch (err) {
    console.log("---> err in changeresetpassword -->", err);
    next(err);
  }
}
