import axios from "axios";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Ensure environment variables are loaded before using them
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..", "..");
const rootEnvPath = path.join(projectRoot, ".env");
if (fs.existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
} else {
  dotenv.config();
}

class ZoomService {
  constructor() {
    this.clientId = process.env.ZOOM_CLIENT_ID;
    this.clientSecret = process.env.ZOOM_CLIENT_SECRET;
    this.accountId = process.env.ZOOM_ACCOUNT_ID;
    this.baseURL = "https://api.zoom.us/v2";
    this.tokenURL = "https://zoom.us/oauth/token";
    this.accessToken = null;
    this.tokenExpiresAt = null;
  }

  // Get OAuth access token using Server-to-Server OAuth
  async getAccessToken() {
    try {
      // Return cached token if valid
      if (
        this.accessToken &&
        this.tokenExpiresAt &&
        Date.now() < this.tokenExpiresAt
      ) {
        return this.accessToken;
      }

      const params = new URLSearchParams();
      params.append("grant_type", "account_credentials");
      params.append("account_id", this.accountId);

      const response = await axios.post(
        this.tokenURL, // e.g., "https://zoom.us/oauth/token"
        params,
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          auth: {
            username: this.clientId,
            password: this.clientSecret,
          },
        }
      );

      if (response.data.access_token) {
        this.accessToken = response.data.access_token;
        this.tokenExpiresAt =
          Date.now() + response.data.expires_in * 1000 - 5 * 60 * 1000;

        console.log("✅ Zoom OAuth token obtained successfully");
        return this.accessToken;
      } else {
        throw new Error("No access token received from Zoom");
      }
    } catch (error) {
      console.error(
        "❌ Error obtaining Zoom OAuth token:",
        error.response?.data || error.message
      );
      throw new Error("Failed to obtain Zoom access token");
    }
  }

  // Create a Zoom meeting
  async createMeeting(topic, startTime, duration = 30) {
    try {
      const accessToken = await this.getAccessToken();

      // The startTime parameter is already in UTC from the frontend
      // The timeZone field in Zoom API is for display purposes only
      // We don't need to adjust the time, just use it as is

      const meetingData = {
        topic: topic,
        type: 2, // Scheduled meeting
        start_time: startTime.toISOString(), // Use the time as received (already UTC)
        duration: duration,
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: false,
          mute_upon_entry: true,
          watermark: false,
          use_pmi: false,
          approval_type: 0,
          audio: "both",
          auto_recording: "none",
        },
        timeZone: "UTC", // ✅ prevents unwanted conversion
        // timeZone: timeZone, // This is just for display in Zoom interface
      };

      console.log(
        "  - Final meeting data:",
        JSON.stringify(meetingData, null, 2)
      );

      const response = await axios.post(
        `${this.baseURL}/users/me/meetings`,
        meetingData,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
        }
      );
      console.log("response.data", response.data);
      return {
        success: true,
        meetingId: response.data.id,
        joinUrl: response.data.join_url,
        startUrl: response.data.start_url,
        password: response.data.password,
      };
    } catch (error) {
      console.error(
        "Error creating Zoom meeting:",
        error.response?.data || error.message
      );
      throw new Error("Failed to create Zoom meeting");
    }
  }

  // Get meeting details
  async getMeeting(meetingId) {
    try {
      const accessToken = await this.getAccessToken();

      const response = await axios.get(
        `${this.baseURL}/meetings/${meetingId}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
        }
      );

      return response.data;
    } catch (error) {
      console.error(
        "Error getting Zoom meeting:",
        error.response?.data || error.message
      );
      throw new Error("Failed to get Zoom meeting details");
    }
  }

  // Delete a meeting
  async deleteMeeting(meetingId) {
    try {
      const accessToken = await this.getAccessToken();

      await axios.delete(`${this.baseURL}/meetings/${meetingId}`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      });

      return { success: true };
    } catch (error) {
      console.error(
        "Error deleting Zoom meeting:",
        error.response?.data || error.message
      );
      throw new Error("Failed to delete Zoom meeting");
    }
  }

  // Clear cached token (useful for testing)
  clearCachedToken() {
    this.accessToken = null;
    this.tokenExpiresAt = null;
    console.log("Zoom OAuth token cache cleared");
  }

  // Get token status (useful for debugging)
  getTokenStatus() {
    return {
      hasToken: !!this.accessToken,
      expiresAt: this.tokenExpiresAt,
      isExpired: this.tokenExpiresAt ? Date.now() >= this.tokenExpiresAt : true,
      timeUntilExpiry: this.tokenExpiresAt
        ? this.tokenExpiresAt - Date.now()
        : null,
    };
  }
}

export default new ZoomService();
